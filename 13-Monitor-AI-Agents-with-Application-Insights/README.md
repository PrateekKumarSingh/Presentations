# Monitoring Agents with Azure Application Insights

This folder contains a minimal working demo for tracing a LangGraph agent into Application Insights.

## Required Files

- `LangGraph_AgentsView_Examples.ipynb` - notebook for live demo flow
- `code/langraph_agent.py` - interactive demo agent
- `code/otel_instrumentation.py` - tracing helpers
- `code/travel_tools.py` - weather and search tools
- `requirements.txt` - Python dependencies
- `KQL_QUERIES.md` - query set for telemetry analysis
- `.env.template` - environment variable template

## Quick Start

1. Create a virtual environment and install dependencies.
2. Copy `.env.template` to `.env` and set telemetry configuration.
3. Run the notebook or the CLI agent.

## Run CLI Demo

```bash
cd 13-Monitor-AI-Agents-with-Application-Insights
source .venv/bin/activate
python code/langraph_agent.py
```

## Run Notebook Demo

Open `LangGraph_AgentsView_Examples.ipynb` and execute cells in order.

## Notes

- Weather data uses Open-Meteo (free).
- Search data uses DuckDuckGo Instant Answer (free, limited coverage).
- Application Insights ingestion and retention are usage based.
