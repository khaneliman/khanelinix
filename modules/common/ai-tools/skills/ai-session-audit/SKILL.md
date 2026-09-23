---
name: ai-session-audit
description: "Audit coding-agent sessions and mine cross-harness history for recurring corrections, skill-routing gaps, and harness faults. Use for retrospective AI-tool efficacy checks or history-driven tuning of skills and shared context."
---

# AI Session Audit

Extract deterministic facts before semantic judgment. Choose one lane:

- **History retrospective** reads an AgentsView archive, including prompts and
  replies, to find what users keep correcting and whether rule changes stuck.
  Use it for a history review, a tune-up of skills or shared context, or a
  fresh-start review after a model change.
- **Scrubbed metrics** read T3 canonical provider events and never emit prompt
  or tool content. Use them for tool, worker, token, and model-route counts.

## History retrospective

```bash
python3 <skill-dir>/scripts/history_audit.py status
python3 <skill-dir>/scripts/history_audit.py run \
  --out "${XDG_CACHE_HOME:-$HOME/.cache}/ai-session-audit/<date>" \
  --since <date> --boundary <policy-change-date> \
  --skills-root <canonical-skills-root>
```

`run` writes cleaned prompts, threads, routing, phrase, and signal tables, and
chunked worker digests. The `extract`, `threads`, `digest`, `corrections`,
`routing`, `phrases`, and `signals` commands rerun one stage in a run directory.
`ledger --file <instruction-file> --out <dir>` traces the commit behind each
rule block. Add routing triggers, aliases, or edit suffixes in
[assets/routing-triggers.json](assets/routing-triggers.json).

1. Follow [references/retrospective.md](references/retrospective.md) from
   coverage through delivery; each stage ends with a completion check.
2. Read [references/rubrics.md](references/rubrics.md) before spawning
   classification workers.
3. Read [references/fresh-start.md](references/fresh-start.md) when a new model
   or harness replaces the default.
4. Read [references/backends.md](references/backends.md) before syncing or
   querying the archive.

## Scrubbed metrics

```bash
python3 <skill-dir>/scripts/ai_session_audit.py summary \
  --since 2026-08-20 --format markdown
python3 <skill-dir>/scripts/ai_session_audit.py events \
  --since 2026-08-20 --output audit.ndjson
```

Use `--provider`, `--thread`, and `--until` to narrow either command. Output
goes to stdout unless `--output` is explicit. Existing output requires
`--force`.

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

- Keep source logs and the archive read-only.
- Scrubbed lane: do not emit prompts, commands, tool arguments, tool results,
  reasoning, or assistant prose.
- History lane: write only under the run directory, whose files are owner-only.
  Quote short user excerpts in reports; never publish digests or paste them into
  public prose. Digests hold raw prompts; send them only to workers on providers
  that already hold that history.
- Do not present processed-token observations as billed usage or cost.
- Do not compare policy revisions without a verified activation boundary; label
  commit-date windows approximate.
- Do not treat more tools, workers, tokens, or turns as inherently better. A
  missing complaint does not prove that a rule is unnecessary.
