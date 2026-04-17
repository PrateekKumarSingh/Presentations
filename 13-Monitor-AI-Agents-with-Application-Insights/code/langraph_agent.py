"""Very simple LangGraph agent with telemetry for tool calls, cost, and failures.

Run:
    python langraph_agent.py

Env:
    AZURE_MONITOR_CONNECTION_STRING=<app insights connection string>
"""

import os
import logging
import json
from pathlib import Path
from typing import TypedDict
from contextlib import nullcontext
from opentelemetry.trace import Status, StatusCode

from langgraph.graph import StateGraph
from openai import OpenAI, AzureOpenAI
from dotenv import load_dotenv

from travel_tools import get_weather, web_search
from otel_instrumentation import (
    AgentInstrumentation,
    agent_span,
    llm_span,
    tool_span,
    estimate_cost_usd,
    record_failure,
)


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load .env for CLI usage so provider/model settings are picked up automatically.
load_dotenv(Path(__file__).resolve().parents[1] / ".env")

# Keep CLI output clean: suppress verbose HTTP request/response logs.
for _name in [
    "httpx",
    "azure.core.pipeline.policies.http_logging_policy",
    "azure.monitor.opentelemetry.exporter",
    "openai",
]:
    logging.getLogger(_name).setLevel(logging.WARNING)


class AgentState(TypedDict, total=False):
    user_request: str
    destination: str
    weather: dict
    search_results: list
    itinerary: str
    input_tokens: int
    output_tokens: int
    cost_usd: float
    tool_failure: bool
    tool_failure_reason: str
    overall_status: str
    step_statuses: dict


class SimpleLangGraphAgent:
    def __init__(self, tracer=None):
        self.tracer = tracer
        self.llm_provider = os.getenv("LLM_PROVIDER", "openai").strip().lower()
        self.llm_model = os.getenv("LLM_MODEL", "gpt-4o-mini").strip()
        self._llm_client = self._build_llm_client()
        self.graph = self._build_graph()

    def _build_llm_client(self):
        """Build OpenAI/Azure OpenAI client from environment settings."""
        if self.llm_provider == "azure":
            api_key = os.getenv("AZURE_OPENAI_API_KEY", "").strip()
            endpoint = (
                os.getenv("AZURE_OPENAI_ENDPOINT", "").strip()
                or os.getenv("AZURE_AI_PROJECT_ENDPOINT", "").strip()
            )
            api_version = os.getenv("AZURE_OPENAI_API_VERSION", "2024-06-01")
            if not api_key or not endpoint:
                raise ValueError(
                    "AZURE_OPENAI_API_KEY and AZURE_OPENAI_ENDPOINT (or AZURE_AI_PROJECT_ENDPOINT) are required when LLM_PROVIDER=azure"
                )

            # Azure AI Foundry project endpoint path is OpenAI-compatible via base_url.
            if "services.ai.azure.com" in endpoint or "/api/projects/" in endpoint:
                base_url = endpoint.rstrip("/")
                if base_url.endswith("/responses"):
                    base_url = base_url[: -len("/responses")]
                if not base_url.endswith("/openai/v1"):
                    base_url = f"{base_url}/openai/v1"
                return OpenAI(api_key=api_key, base_url=base_url)

            return AzureOpenAI(api_key=api_key, azure_endpoint=endpoint, api_version=api_version)

        api_key = os.getenv("OPENAI_API_KEY", "").strip()
        if not api_key:
            raise ValueError("OPENAI_API_KEY is required when LLM_PROVIDER=openai")
        return OpenAI(api_key=api_key)

    def _invoke_llm(self, operation_name: str, system_prompt: str, user_prompt: str) -> tuple[str, int, int, float]:
        """Invoke the configured LLM and return content + usage metrics."""
        if self.tracer:
            with llm_span(self.tracer, self.llm_model, operation_name) as span:
                response = self._llm_client.chat.completions.create(
                    model=self.llm_model,
                    messages=[
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": user_prompt},
                    ],
                    temperature=0.2,
                )
                usage = response.usage
                input_tokens = int(getattr(usage, "prompt_tokens", 0) or 0)
                output_tokens = int(getattr(usage, "completion_tokens", 0) or 0)
                step_cost = estimate_cost_usd(input_tokens, output_tokens)

                span.set_attribute("gen_ai.usage.input_tokens", input_tokens)
                span.set_attribute("gen_ai.usage.output_tokens", output_tokens)
                span.set_attribute("gen_ai.usage.estimated_cost_usd", step_cost)

                content = (response.choices[0].message.content or "").strip()
                return content, input_tokens, output_tokens, step_cost

        response = self._llm_client.chat.completions.create(
            model=self.llm_model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            temperature=0.2,
        )
        usage = response.usage
        input_tokens = int(getattr(usage, "prompt_tokens", 0) or 0)
        output_tokens = int(getattr(usage, "completion_tokens", 0) or 0)
        step_cost = estimate_cost_usd(input_tokens, output_tokens)
        content = (response.choices[0].message.content or "").strip()
        return content, input_tokens, output_tokens, step_cost

    def _build_graph(self):
        builder = StateGraph(AgentState)
        builder.add_node("parse_request", self.parse_request)
        builder.add_node("fetch_external_data", self.call_tools)
        builder.add_node("compose_itinerary", self.finalize_response)

        builder.set_entry_point("parse_request")
        builder.add_edge("parse_request", "fetch_external_data")
        builder.add_edge("fetch_external_data", "compose_itinerary")
        builder.set_finish_point("compose_itinerary")

        return builder.compile()

    def parse_request(self, state: AgentState) -> AgentState:
        node_ctx = (
            self.tracer.start_as_current_span("parse_request") if self.tracer else nullcontext()
        )
        with node_ctx as node_span:
            request = state["user_request"]
            system_prompt = (
                "Extract destination city from the user's travel request. "
                "Return strict JSON with key 'destination'."
            )
            user_prompt = f"User request: {request}"

            content, input_tokens, output_tokens, step_cost = self._invoke_llm(
                operation_name="parse_request",
                system_prompt=system_prompt,
                user_prompt=user_prompt,
            )

            destination = "Tokyo"
            try:
                parsed = json.loads(content)
                destination = str(parsed.get("destination", "Tokyo")).strip() or "Tokyo"
            except Exception:
                if "tokyo" in request.lower():
                    destination = "Tokyo"
                elif "paris" in request.lower():
                    destination = "Paris"

            step_statuses = {**state.get("step_statuses", {})}
            step_statuses["parse_request"] = "success"

            if node_span:
                node_span.set_attribute("step.name", "parse_request")
                node_span.set_attribute("step.status", "success")
                node_span.set_status(Status(StatusCode.OK))

            return {
                **state,
                "destination": destination,
                "input_tokens": state.get("input_tokens", 0) + input_tokens,
                "output_tokens": state.get("output_tokens", 0) + output_tokens,
                "cost_usd": state.get("cost_usd", 0.0) + step_cost,
                "step_statuses": step_statuses,
            }

    def call_tools(self, state: AgentState) -> AgentState:
        node_ctx = (
            self.tracer.start_as_current_span("fetch_external_data") if self.tracer else nullcontext()
        )
        with node_ctx as node_span:
            destination = state["destination"]
            tool_failure = False
            tool_failure_reason = ""
            step_statuses = {**state.get("step_statuses", {})}

            if self.tracer:
                with tool_span(self.tracer, "get_weather") as span:
                    weather = get_weather(destination, "Dec 1-5")
                    span.set_attribute("http.status_code", 200)
                    span.set_attribute("db.response.count", 1)
            else:
                weather = get_weather(destination, "Dec 1-5")

            try:
                # Keep existing demo keyword for failure simulation compatibility
                if "failure_simulation" in state["user_request"].lower():
                    raise TimeoutError("Simulated web search timeout")

                if self.tracer:
                    with tool_span(self.tracer, "web_search") as span:
                        results = web_search(f"best places to stay in {destination}", limit=5)
                        span.set_attribute("http.status_code", 200)
                        span.set_attribute("db.response.count", len(results))
                        span.set_attribute("tool_params.limit", 5)
                else:
                    results = web_search(f"best places to stay in {destination}", limit=5)

            except Exception as err:
                tool_failure = True
                tool_failure_reason = str(err)
                if self.tracer:
                    with tool_span(self.tracer, "web_search") as span:
                        record_failure(
                            span=span,
                            error=err,
                            operation_name="web_search",
                            status_code=504,
                            retry_count=1,
                        )
                results = []

            step_statuses["fetch_external_data"] = "failed" if tool_failure else "success"

            if node_span:
                node_span.set_attribute("step.name", "fetch_external_data")
                node_span.set_attribute("step.status", step_statuses["fetch_external_data"])
                if tool_failure:
                    node_span.set_status(Status(StatusCode.ERROR, tool_failure_reason or "tool_failure"))
                    node_span.set_attribute("error.message", tool_failure_reason or "tool_failure")
                else:
                    node_span.set_status(Status(StatusCode.OK))

            return {
                **state,
                "weather": weather,
                "search_results": results,
                "tool_failure": tool_failure,
                "tool_failure_reason": tool_failure_reason,
                "step_statuses": step_statuses,
            }

    def finalize_response(self, state: AgentState) -> AgentState:
        node_ctx = (
            self.tracer.start_as_current_span("compose_itinerary") if self.tracer else nullcontext()
        )
        with node_ctx as node_span:
            weather = state["weather"]
            top_results = state.get("search_results", [])[:3]

            system_prompt = (
                "You are a travel planner. Create a concise 3-day itinerary from the provided facts. "
                "Use plain text with clear day-wise bullets."
            )
            user_prompt = (
                f"Destination: {state['destination']}\n"
                f"Weather: {json.dumps(weather)}\n"
                f"Web search results: {json.dumps(top_results)}\n"
                "Generate the final itinerary."
            )

            itinerary, input_tokens, output_tokens, step_cost = self._invoke_llm(
                operation_name="finalize_response",
                system_prompt=system_prompt,
                user_prompt=user_prompt,
            )

            step_statuses = {**state.get("step_statuses", {})}
            step_statuses["compose_itinerary"] = "success"
            overall_status = "failed" if state.get("tool_failure", False) else "success"

            if node_span:
                node_span.set_attribute("step.name", "compose_itinerary")
                node_span.set_attribute("step.status", "success")
                node_span.set_status(Status(StatusCode.OK))

            return {
                **state,
                "itinerary": itinerary,
                "input_tokens": state.get("input_tokens", 0) + input_tokens,
                "output_tokens": state.get("output_tokens", 0) + output_tokens,
                "cost_usd": state.get("cost_usd", 0.0) + step_cost,
                "step_statuses": step_statuses,
                "overall_status": overall_status,
            }

    def run(self, user_request: str) -> AgentState:
        initial_state: AgentState = {
            "user_request": user_request,
            "input_tokens": 0,
            "output_tokens": 0,
            "cost_usd": 0.0,
            "overall_status": "in_progress",
            "step_statuses": {},
        }

        if not self.tracer:
            return self.graph.invoke(initial_state)

        with agent_span(self.tracer, "simple_travel_agent", {"user.request": user_request}) as root_span:
            try:
                result = self.graph.invoke(initial_state)
                overall_status = result.get("overall_status", "success")
                root_span.set_attribute("status", overall_status)
                root_span.set_attribute("gen_ai.usage.input_tokens", result["input_tokens"])
                root_span.set_attribute("gen_ai.usage.output_tokens", result["output_tokens"])
                root_span.set_attribute("gen_ai.usage.estimated_cost_usd", result["cost_usd"])
                for step_name, step_status in result.get("step_statuses", {}).items():
                    root_span.set_attribute(f"step.{step_name}.status", step_status)

                if overall_status == "failed":
                    root_span.set_status(
                        Status(StatusCode.ERROR, result.get("tool_failure_reason", "step_failure"))
                    )
                else:
                    root_span.set_status(Status(StatusCode.OK))

                return result
            except Exception as err:
                record_failure(root_span, err, "simple_travel_agent")
                raise


def setup_tracing() -> tuple:
    connection_string = (
        os.getenv("AZURE_MONITOR_CONNECTION_STRING")
        or os.getenv("APPLICATION_INSIGHTS_CONNECTION_STRING")
    )
    if not connection_string:
        logger.warning(
            "No monitor connection string found (AZURE_MONITOR_CONNECTION_STRING or APPLICATION_INSIGHTS_CONNECTION_STRING). Running without export."
        )
        return None, None

    instrumentation = AgentInstrumentation(
        connection_string=connection_string,
        service_name="simple-langgraph-agent",
        environment=os.getenv("ENVIRONMENT", "demo"),
    )
    tracer = instrumentation.get_tracer(__name__)
    return instrumentation, tracer


def main():
    instrumentation, tracer = setup_tracing()
    try:
        agent = SimpleLangGraphAgent(tracer=tracer)
    except ValueError as exc:
        print(f"Configuration error: {exc}")
        print(
            "Set OPENAI_API_KEY for OpenAI mode, or AZURE_OPENAI_API_KEY + AZURE_OPENAI_ENDPOINT (or AZURE_AI_PROJECT_ENDPOINT) for Azure mode."
        )
        return

    print("\nSimple LangGraph Agent (Interactive)")
    print("Type your travel request and press Enter.")
    print("Type 'exit' to quit. Include 'failure_simulation' in prompt to simulate tool failure.\n")

    try:
        while True:
            request = input("You: ").strip()
            if not request:
                continue
            if request.lower() in {"exit", "quit", "q"}:
                print("Goodbye.")
                break

            result = agent.run(request)

            print("\nAgent Result")
            print("-" * 40)
            print(result["itinerary"])
            print("\nTelemetry Summary")
            print(f"Input tokens:  {result['input_tokens']}")
            print(f"Output tokens: {result['output_tokens']}")
            print(f"Est. cost USD: ${result['cost_usd']:.6f}\n")

    finally:
        if instrumentation:
            instrumentation.shutdown()


if __name__ == "__main__":
    main()
