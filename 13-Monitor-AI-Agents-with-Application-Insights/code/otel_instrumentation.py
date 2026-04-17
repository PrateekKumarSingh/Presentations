"""
OpenTelemetry Instrumentation Setup for AI Agents
Reusable module for instrumenting LangGraph and custom agents.

This module provides:
1. Azure Monitor Trace Exporter configuration
2. OpenTelemetry TracerProvider setup
3. Helper functions for creating Gen AI spans
4. Best practices for instrumentation
"""

import os
from typing import Optional, Dict, Any
from contextlib import contextmanager

from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from azure.monitor.opentelemetry.exporter import AzureMonitorTraceExporter


class AgentInstrumentation:
    """
    Handles OpenTelemetry setup for AI agents.
    
    Usage:
        instrumentation = AgentInstrumentation(connection_string="...")
        tracer = instrumentation.get_tracer(__name__)
        
        with tracer.start_as_current_span("agent_run") as span:
            span.set_attribute("gen_ai.operation.name", "travel_planning")
            # ... agent logic ...
    """
    
    def __init__(
        self,
        connection_string: str,
        service_name: str = "ai-agent",
        environment: str = "production"
    ):
        """
        Initialize OpenTelemetry with Azure Monitor exporter.
        
        Args:
            connection_string: Azure Monitor connection string
            service_name: Service name for identification
            environment: Environment (production, staging, dev)
        """
        self.connection_string = connection_string
        self.service_name = service_name
        self.environment = environment
        
        # Create exporter
        self.exporter = AzureMonitorTraceExporter(
            connection_string=connection_string
        )
        
        # Create TracerProvider
        self.trace_provider = TracerProvider()
        self.trace_provider.add_span_processor(
            BatchSpanProcessor(self.exporter)
        )
        
        # Set as global provider
        trace.set_tracer_provider(self.trace_provider)
        
        print(f"✅ OpenTelemetry initialized for {service_name} ({environment})")
    
    def get_tracer(self, module_name: str):
        """Get a tracer for a specific module."""
        return trace.get_tracer(module_name)
    
    def shutdown(self):
        """Gracefully shut down the tracer provider."""
        self.trace_provider.force_flush()


# ============================================================================
# Helper Functions for Gen AI Spans
# ============================================================================

@contextmanager
def agent_span(tracer, operation_name: str, attributes: Optional[Dict[str, Any]] = None):
    """
    Context manager for agent operation spans.
    
    Usage:
        with agent_span(tracer, "travel_planning", {"user_id": "user123"}) as span:
            # ... agent logic ...
    """
    with tracer.start_as_current_span(operation_name) as span:
        span.set_attribute("gen_ai.operation.name", operation_name)
        span.set_attribute("span.kind", "INTERNAL")
        
        if attributes:
            for key, value in attributes.items():
                span.set_attribute(key, value)
        
        yield span


@contextmanager
def llm_span(
    tracer,
    model_name: str,
    operation_type: str = "chat.completions"
):
    """
    Context manager for LLM call spans.
    
    Usage:
        with llm_span(tracer, "gpt-4-turbo") as span:
            response = llm_call(...)
            span.set_attribute("gen_ai.usage.input_tokens", ...)
            span.set_attribute("gen_ai.usage.output_tokens", ...)
    """
    with tracer.start_as_current_span(f"llm_call_{model_name}") as span:
        span.set_attribute("gen_ai.system", "OpenAI")
        span.set_attribute("gen_ai.request.model", model_name)
        span.set_attribute("gen_ai.operation.name", operation_type)
        span.set_attribute("span.kind", "CLIENT")
        
        yield span


@contextmanager
def tool_span(tracer, tool_name: str):
    """
    Context manager for tool call spans.
    
    Usage:
        with tool_span(tracer, "weather_api") as span:
            result = weather_api_call(...)
            span.set_attribute("db.response.documents", len(result))
    """
    with tracer.start_as_current_span(f"tool_{tool_name}") as span:
        span.set_attribute("db.operation", tool_name)
        span.set_attribute("span.kind", "CLIENT")
        
        yield span


# ============================================================================
# Token Usage Tracker
# ============================================================================

class TokenUsageTracker:
    """Track token usage across an agent run."""
    
    def __init__(self, span):
        self.span = span
        self.total_input_tokens = 0
        self.total_output_tokens = 0
        self.input_tokens_by_model = {}
        self.output_tokens_by_model = {}
    
    def record_llm_call(
        self,
        model: str,
        input_tokens: int,
        output_tokens: int
    ):
        """Record tokens from an LLM call."""
        self.total_input_tokens += input_tokens
        self.total_output_tokens += output_tokens
        
        self.input_tokens_by_model[model] = self.input_tokens_by_model.get(model, 0) + input_tokens
        self.output_tokens_by_model[model] = self.output_tokens_by_model.get(model, 0) + output_tokens
        
        # Update span
        self.span.set_attribute("gen_ai.usage.input_tokens", self.total_input_tokens)
        self.span.set_attribute("gen_ai.usage.output_tokens", self.total_output_tokens)
    
    def get_summary(self):
        """Get token usage summary."""
        return {
            "total_input": self.total_input_tokens,
            "total_output": self.total_output_tokens,
            "by_model": {
                "input": self.input_tokens_by_model,
                "output": self.output_tokens_by_model
            }
        }


def estimate_cost_usd(
    input_tokens: int,
    output_tokens: int,
    input_price_per_million: float = 0.01,
    output_price_per_million: float = 0.03
) -> float:
    """Estimate request cost using per-million token pricing."""
    input_cost = (input_tokens / 1_000_000) * input_price_per_million
    output_cost = (output_tokens / 1_000_000) * output_price_per_million
    return round(input_cost + output_cost, 8)


def record_failure(
    span,
    error: Exception,
    operation_name: str,
    status_code: Optional[int] = None,
    retry_count: Optional[int] = None,
):
    """Record standardized failure attributes for easier filtering in Agents View."""
    span.set_attribute("status", "error")
    span.set_attribute("error.type", type(error).__name__)
    span.set_attribute("error.message", str(error))
    span.set_attribute("gen_ai.operation.name", operation_name)
    if status_code is not None:
        span.set_attribute("http.status_code", status_code)
    if retry_count is not None:
        span.set_attribute("retry.count", retry_count)


# ============================================================================
# Configuration from Environment
# ============================================================================

def setup_from_env() -> AgentInstrumentation:
    """
    Setup instrumentation from environment variables.
    
    Environment variables:
        AZURE_MONITOR_CONNECTION_STRING: Required. Connection string for Application Insights
        SERVICE_NAME: Optional. Defaults to "ai-agent"
        ENVIRONMENT: Optional. Defaults to "production"
    """
    connection_string = os.getenv("AZURE_MONITOR_CONNECTION_STRING")
    if not connection_string:
        raise ValueError(
            "AZURE_MONITOR_CONNECTION_STRING environment variable not set. "
            "Get it from your Application Insights resource in Azure Portal."
        )
    
    service_name = os.getenv("SERVICE_NAME", "ai-agent")
    environment = os.getenv("ENVIRONMENT", "production")
    
    return AgentInstrumentation(
        connection_string=connection_string,
        service_name=service_name,
        environment=environment
    )


# ============================================================================
# Example Usage
# ============================================================================

if __name__ == "__main__":
    # Example: How to use this module
    
    # 1. Initialize instrumentation
    instrumentation = AgentInstrumentation(
        connection_string="InstrumentationKey=YOUR_KEY",  # Replace with real key
        service_name="travel_planner",
        environment="demo"
    )
    
    tracer = instrumentation.get_tracer("demo_agent")
    
    # 2. Create an agent span
    with agent_span(tracer, "plan_trip", {"user_id": "user123"}) as span:
        tracker = TokenUsageTracker(span)
        
        # 3. Create an LLM span
        with llm_span(tracer, "gpt-4-turbo") as llm_sp:
            # Simulate LLM call
            input_tokens, output_tokens = 150, 50
            tracker.record_llm_call("gpt-4-turbo", input_tokens, output_tokens)
            print(f"LLM Call: {input_tokens} input, {output_tokens} output tokens")

            # Cost tracking example
            estimated_cost = estimate_cost_usd(input_tokens, output_tokens)
            llm_sp.set_attribute("gen_ai.usage.estimated_cost_usd", estimated_cost)
            print(f"Estimated LLM cost: ${estimated_cost}")
        
        # 4. Create a tool span
        with tool_span(tracer, "weather_api") as tool_sp:
            # Simulate tool call
            print("Tool Call: Weather API")
            tool_sp.set_attribute("http.status_code", 200)

        # Failure tracking example (simulated)
        with tool_span(tracer, "hotel_api") as tool_sp:
            try:
                raise TimeoutError("Hotel API timeout after 5s")
            except Exception as err:
                record_failure(
                    span=tool_sp,
                    error=err,
                    operation_name="hotel_lookup",
                    status_code=504,
                    retry_count=2,
                )
                print("Recorded failure attributes for hotel_api")
    
    # 5. Shutdown
    instrumentation.shutdown()
    print("✅ Traces sent to Application Insights")
