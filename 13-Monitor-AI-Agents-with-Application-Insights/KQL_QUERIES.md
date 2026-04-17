# KQL Queries for Agent Monitoring

Use in Azure Portal: Application Insights -> Logs.

All queries target `customMetrics` and `customDimensions` emitted by tracing.

## 1. Most Expensive Operations (Last 24h)

```kql
customMetrics
| where name == "gen_ai.usage.output_tokens"
| extend operation_name = tostring(customDimensions["gen_ai.operation.name"])
| extend model = tostring(customDimensions["gen_ai.request.model"])
| summarize
    total_output_tokens = sum(value),
    avg_output_tokens = avg(value),
    max_output_tokens = max(value),
    operation_count = dcount(operation_id)
    by operation_name, model
| order by total_output_tokens desc
```

## 2. Slowest Operations (Last 24h)

```kql
customMetrics
| where name == "duration"
| extend operation_name = tostring(customDimensions["operation_name"])
| extend status = tostring(customDimensions["status"])
| where status == "success"
| summarize
    avg_duration_ms = avg(value),
    max_duration_ms = max(value),
    p95_duration = percentile(value, 95),
    operation_count = dcount(operation_id)
    by operation_name
| order by p95_duration desc
```

## 3. Error Rate by Operation

```kql
customMetrics
| where name == "gen_ai.operation.status"
| extend operation_name = tostring(customDimensions["gen_ai.operation.name"])
| extend status = tostring(customDimensions["status"])
| summarize
    total_runs = dcount(operation_id),
    failures = countif(status == "error"),
    error_rate = (todouble(countif(status == "error")) / dcount(operation_id)) * 100
    by operation_name
| where error_rate > 0
| order by error_rate desc
```

## 4. Tool Failure Breakdown

```kql
customMetrics
| where name == "duration"
| extend
    tool_name = tostring(customDimensions["db.operation"]),
    operation_name = tostring(customDimensions["gen_ai.operation.name"]),
    status = tostring(customDimensions["status"]),
    status_code = toint(customDimensions["http.status_code"]),
    error_type = tostring(customDimensions["error.type"]),
    retry_count = toint(customDimensions["retry.count"])
| where isnotempty(tool_name)
| summarize
    total_calls = count(),
    failed_calls = countif(status == "error" or status_code >= 400),
    timeout_errors = countif(error_type has "Timeout" or status_code == 504),
    throttling_429 = countif(status_code == 429),
    server_5xx = countif(status_code between (500 .. 599)),
    avg_retry_count = avg(retry_count)
    by tool_name, operation_name
| extend failure_rate = (todouble(failed_calls) / total_calls) * 100
| where failed_calls > 0
| order by failure_rate desc
```

## 5. Top Failed Traces

```kql
customMetrics
| extend
    run_id = operation_id,
    operation_name = tostring(customDimensions["gen_ai.operation.name"]),
    error_message = tostring(customDimensions["error.message"]),
    error_type = tostring(customDimensions["error.type"]),
    status_code = toint(customDimensions["http.status_code"]),
    status = tostring(customDimensions["status"]),
    retry_count = toint(customDimensions["retry.count"])
| where status == "error" or status_code >= 400 or isnotempty(error_message)
| summarize
    first_seen = min(timestamp),
    last_seen = max(timestamp),
    hit_count = count(),
    sample_error = any(error_message),
    sample_error_type = any(error_type),
    sample_status_code = any(status_code),
    sample_retry_count = any(retry_count)
    by run_id, operation_name
| order by last_seen desc
| take 20
```

## References

- https://learn.microsoft.com/azure/kusto/query/
- https://learn.microsoft.com/azure/azure-monitor/app/app-insights-metrics
- https://opentelemetry.io/docs/specs/semconv/gen-ai/
