---
name: ai-session-audit
description: "Audit retained coding-agent sessions, tools, workers, tokens, and routing. Use for retrospective AI-tool efficacy checks."
---

# AI Session Audit

Extract deterministic facts before making semantic judgments about agent
quality. The bundled command reads T3 canonical provider events from existing
logs. It does not inspect T3's private database or copy prompt and tool content
into its output.

## Commands

Run a bounded summary:

```bash
python3 <skill-dir>/scripts/ai_session_audit.py summary \
  --since 2026-08-20 --format markdown
```

Export scrubbed events for DuckDB or another analytics backend:

```bash
python3 <skill-dir>/scripts/ai_session_audit.py events \
  --since 2026-08-20 --output audit.ndjson
```

Use `--provider`, `--thread`, and `--until` to narrow either command. Output
goes to stdout unless `--output` is explicit. Existing output requires
`--force`.

## Workflow

1. Run `summary` against the smallest useful date range.
2. Treat tool order, turn count, provider-reported tokens, skill observations,
   worker tasks, and model routes as deterministic evidence.
3. Read [references/schema.md](references/schema.md) before comparing providers
   or interpreting token and task fields.
4. Use `events` when longitudinal queries or visualization justify a database.
   Read [references/backends.md](references/backends.md) before selecting one.
5. Separate observed behavior from inferred policy compliance. A transcript can
   prove that a skill ran. Deciding whether one should have run still requires a
   frozen routing corpus or a reviewed rubric.

## Boundaries

- Keep source logs read-only.
- Do not emit prompts, commands, tool arguments, tool results, reasoning, or
  assistant prose.
- Do not present processed-token observations as billed usage or cost.
- Do not compare policy revisions unless the report records a revision label or
  another verified activation boundary.
- Do not treat more tools, workers, tokens, or turns as inherently better.
