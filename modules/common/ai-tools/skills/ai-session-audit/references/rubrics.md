# Classification Worker Packets

Give each read-only worker one digest chunk and one packet. Fill the
placeholders; keep labels, output, and constraints unchanged so reports from
different runs compare. Name the semantic role the task needs, such as
`fact-finder`; do not name a model without user intent.

## Shared packet fields

- **Input:** `<run-dir>/digests/<kind>-<n>.md`. Read it fully with offsets when
  it exceeds one read.
- **Policy:** the current rule file the complaints are judged against, with line
  numbers: `pr-review.md` for review digests, the shared base context for
  correction and orchestration digests.
- **Context:** `<user role and projects>`; the digest format; the windows
  `<boundary list>` with the rule change each boundary marks.
- **Constraints:** read-only; no file writes or network; quote verbatim only
  from USER lines that are not relayed reports; paraphrase AGENT lines; never
  reproduce anything resembling a token, key, or password; do not invoke skills
  or spawn workers.
- **Exit:** return the report; at most 1,300 words.

Every packet labels pasted agent or reviewer output as `relayed-report` and
excludes it from the other counts. Relayed findings, `Direct answer:` blocks,
severity keys such as P1, and evidence packets are not the user's words.

## Review threads

Digest format: `## S<n> | agent | date | project | skills | turns`, then
`T<k> USER:` prompts and `T<k> AGENT:` final replies truncated to 600 chars.

Labels, applied to each USER turn from T1 that reacts to the agent or steers the
review: `relayed-report`, `publish-pending` (create or update a pending review
or inline suggestions; do not submit), `tone-wording`, `structure-format`
(labels, suggestion anchors and ranges, grouping, summary body), `evidence`
(tested, validated, confidence, sources), `severity` (blocker calibration, niche
edge cases), `dismissed-finding`, `premise-noise` (premise, redesign, or scope
additions the user rejects), `missed-concern` (existing helper, idiom,
compatibility, convention, test validity), `history-context` (prior threads,
author replies, existing pending review), `maintainer-stance`, `fix-git`,
`other`.

Required output:

1. Table of label to turns and sessions, split by window.
2. Top 10 recurring complaints: sessions per window, two dated USER quotes with
   S-ids, the triggering agent behavior, and coverage in the policy file
   (covered, partial, or not covered, with lines). State when a complaint
   persists after the rule that targets it.
3. What the user cares about: missed-concern themes with counts and examples.
4. What the user dismissed: finding types rejected, with counts and examples.
5. Up to 5 strongest frustration quotes with S-id, date, and cause.
6. Sessions that needed a separate publish-pending turn, per window.

## General corrections

Digest format: `## agent | date | project | first: <excerpt>`, then
`AGENT(prev, tail)` (the reply being corrected) and `USER T<k>`. Turns were
selected by a broad regex, so some are neutral.

One primary label per USER turn: `relayed-report`, `verbosity-format`,
`stopped-early`, `overreach`, `unverified`, `wrong-approach`,
`repeated-instruction`, `git-hygiene`, `environment-tooling`, `harness-model`,
`skill-routing`, `delegation`, `memory-recall`, `product-quality`,
`not-a-correction`, `other`.

Required output:

1. Table of label to turns and sessions, split by window.
2. Top 12 recurring complaints: sessions per window, two dated USER quotes with
   project, the triggering behavior, and coverage in the policy file and any
   named repository guidance, with lines.
3. Durable preferences restated at least twice, with counts and one quote each.
4. Up to 6 strongest frustration quotes with date, project, and cause.
5. Estimated false-positive rate, with and without relayed reports.

## Orchestration threads

Digest format matches general corrections; sessions exceed 45 human turns and
coordinate child agents.

One primary label per USER turn: `relayed-report`, `stall-or-lost-progress`,
`worker-quality`, `routing-quota`, `scope-drift`, `git-state`, `verification`,
`publication-boundary`, `context-memory`, `format-verbosity`,
`not-a-correction`, `other`.

Required output:

1. Table of label to turns and sessions.
2. Top 10 failure patterns: sessions, two dated USER quotes, the coordinator
   behavior, and coverage in the shared base context, provider addenda, and
   worker contract, with lines.
3. Coordination preferences stated repeatedly (worker mix, check-ins, commit
   cadence, verification, cleanup), with counts and one quote each.
4. Up to 5 strongest frustration quotes with date, project, and cause.
