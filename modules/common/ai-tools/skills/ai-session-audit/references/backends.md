# Analytics Backends

Use the bundled summary for ordinary audits. Add a backend only when saved
queries, dashboards, or cross-window comparisons justify the operational cost.

## DuckDB

The `events` output is newline-delimited JSON. DuckDB can read this format with
`read_ndjson_auto`, including file globs, and can persist derived tables or
export Parquet. This is the smallest useful backend for local longitudinal
queries.

Source:
[DuckDB JSON loading documentation](https://duckdb.org/docs/current/data/json/loading_json),
accessed 2026-08-27.

Example:

```sql
SELECT provider, tool_name, count(*) AS calls
FROM read_ndjson_auto('audit.ndjson')
WHERE event_type = 'item.completed' AND tool_name IS NOT NULL
GROUP BY ALL
ORDER BY calls DESC;
```

## AI Observer

AI Observer is a local OpenTelemetry-compatible service with historical import,
watch mode, DuckDB storage, dashboards, cost tables, and Parquet export. Its
native file import expects standard Claude, Codex, or Gemini session paths and
schemas. T3 canonical logs therefore need this skill's adapter or a future OTLP
bridge rather than a path override alone.

Source:
[AI Observer project documentation](https://github.com/tobilg/ai-observer),
accessed 2026-08-27.

## OpenTelemetry sinks

OpenTelemetry defines shared GenAI attributes for model, operation, tool, and
token usage. A future exporter should map scrubbed normalized events to those
attributes instead of defining another wire convention. Tool arguments and
results can contain sensitive information and should remain disabled.

Source:
[OpenTelemetry GenAI attribute registry](https://opentelemetry.io/docs/specs/semconv/registry/attributes/gen-ai/),
accessed 2026-08-27.

Phoenix and Langfuse both accept OTLP and provide trace analysis and evaluation
surfaces. They are reasonable sinks after the local event mapping is stable;
they are not required for extraction.

Sources:
[Phoenix tracing documentation](https://arize.com/docs/phoenix/tracing/llm-traces)
and
[Langfuse public API documentation](https://langfuse.com/docs/api-and-data-platform/features/public-api),
accessed 2026-08-27.
