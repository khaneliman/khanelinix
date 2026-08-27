# T3 Audit Schema

The command reads lines with a `CANON:` payload from T3 provider logs. It
deduplicates events by `eventId`, uses an internal content fingerprint when an
ID is absent, and tolerates a truncated rotated-log tail unless `--strict` is
set. Strict mode rejects missing IDs. Exported events are sorted by timestamp,
event ID, and event type. Timestamps are normalized to UTC before ordering and
duration calculations.

## Source discovery

The default source is:

```text
~/.t3/userdata/logs/provider/events.*.log*
```

`--source` accepts a log file or a directory. Repeat it to combine roots.
Date-only and timezone-free filter values are interpreted as UTC.

## Normalized event

The `events` command emits one JSON object per line with these fields:

- `source_event_id`, `created_at`, `provider`, `thread_id`, and `turn_id`
- optional caller-supplied `policy_revision`
- `event_type`, `item_type`, `status`, and `duration_ms`
- `tool_name`, `skill_names`, and `skill_detection`
- `task_id`, `agent_role`, `model`, `reasoning_effort`, and `scrubbed_fields`
- provider-reported input, cached-input, output, reasoning-output, context, and
  cumulative processed-token values

Every field has a fixed name. Unavailable values are `null` or an empty list.
Raw payloads are never included. Source event, thread, turn, and task IDs are
stable truncated SHA-256 identifiers. Other log-derived strings must match a
fixed schema or current installed-configuration catalog. Unknown string values
become stable `other-<category>-<hash>` pseudonyms. Invalid types become `null`
or `unknown`. `scrubbed_fields` records their field names. Skill names come from
installed `SKILL.md` frontmatter. Model and role names come from the current
`multi-provider-sdlc` routing catalog plus native role names. Known provider
spellings and terminal-format remnants are normalized before aggregation, such
as `inProgress` to `in_progress` and a trailing `[1m]` model artifact.

## Metric meaning

- **Thread:** T3 conversation identifier. It is the closest available session
  boundary.
- **Turn:** Distinct non-null T3 `turnId`. One turn does not prove that the
  user's business task finished.
- **Worker task:** Distinct provider, thread, and `taskId` tuple. These normally
  describe child work, not the parent request. Worker role, model, and effort
  counts use the first start event for that tuple.
- **Tool call:** A completed canonical item with an observable tool name.
  Standard provider tools retain their names. MCP calls use the coarse
  `mcp_tool` category so server and operation names cannot disclose content.
- **Skill observation:** A completed Claude `Skill` call, or a completed Codex
  command containing a path that ends in `skills/<name>/SKILL.md`. The latter is
  labeled `skill-path-reference`. It does not prove that the command read or
  followed the skill.
- **Delegation call:** Claude `Agent` or Codex `spawnAgent`.
- **Processed tokens:** Sum of provider-reported per-update input and output
  fields. Codex `last*` fields take precedence. Cached and reasoning tokens are
  subsets, not additions to the total.
- **Latest context tokens:** Sum of the latest `usedTokens` observation for each
  included thread.

Provider token events do not have identical billing semantics. Use these values
for within-provider trends. The Markdown report separates providers. JSON also
contains an explicitly labeled mixed-provider aggregate. Do not calculate cost
without a dated model-pricing table and a provider-specific billing rule.

Skill tables retain both provider and evidence method. A Claude `Skill` tool
call and a Codex `skill-path-reference` therefore remain separate observations.
Worker models, session models, and requested delegation models also remain
separate because they answer different routing questions.

## Known gaps

- Historical events do not reliably carry the active khanelinix policy revision.
  Pass `--policy-revision` when the activation boundary is known.
- T3 provider logs rotate. Preserve dated normalized exports when trend history
  must outlive the retained raw logs.
- Some Codex root-model metadata is absent from canonical events.
- A skill-path reference does not prove that the model opened or followed the
  skill.
- A missing skill observation can be a parser gap when the provider introduces a
  new item schema. Inspect schema counters before concluding noncompliance.
- Real-session traces cannot measure missed review findings without a labeled or
  seeded answer key.
