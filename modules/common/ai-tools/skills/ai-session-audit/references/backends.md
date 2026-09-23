# Analytics Backends

Use the bundled summary for ordinary audits. Add a backend only when saved
queries, dashboards, or cross-window comparisons justify the operational cost.

## AgentsView archive

The history retrospective reads `~/.agentsview/sessions.db`. AgentsView indexes
Claude, Codex, Gemini CLI, OpenCode, and Antigravity CLI; Antigravity stays in
summary mode without `agy-reader`. The archive keeps sessions after their
sources expire, such as Claude transcripts past `cleanupPeriodDays`, which makes
it the only durable cross-harness history. T3 provider logs and Codex
`logs_2.sqlite` retain days to weeks.

Verified with AgentsView 0.41.1:

- One failing provider fails the whole sync pass. The Warp provider fails when
  `warp.sqlite` lacks `agent_conversations`; point `WARP_DIR` at an empty
  directory.
- AgentsView ignores `CODEX_HOME`. Set `CODEX_SESSIONS_DIR`; it takes one path,
  so an `archived_sessions` root needs `codex_sessions_dirs` in `config.toml`.
- A cold `agentsview sync` starts the daemon, whose startup sync then rejects
  the CLI request. Start the daemon and let its startup or watcher sync run.
- A data-version rebuild can take 13 GB of memory and several times the prior
  database size when transcripts carry inline screenshots.
- `tool_calls.skill_name` misses most Codex skill loads. `history_audit.py` also
  counts reads of installed `SKILL.md` copies.
- `agentsview mcp` exposes read-only session search for tools such as `recall`.

Read the live database read-only, or copy it with `cp --reflink=auto` first when
the daemon is rebuilding.

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
