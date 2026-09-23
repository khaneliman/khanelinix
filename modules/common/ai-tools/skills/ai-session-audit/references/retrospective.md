# History Retrospective

Use for a history review, a tune-up of skills or shared context, or a measured
check of whether a rule change worked. Read [rubrics.md](rubrics.md) before
spawning classification workers. Read [fresh-start.md](fresh-start.md) when a
new model or harness replaces the default. Read [backends.md](backends.md)
before syncing or querying the archive.

## 1. Confirm coverage

Run `history_audit.py status`. A `stale_days` value above 2 means the archive
missed recent work; sync it first. Done when every harness the user named has
sessions inside the window, or the report states the gap.

## 2. Extract

Run `history_audit.py run` with `--since`, one `--boundary` per instruction
change being judged, and `--skills-root` so routing ignores sessions from before
a skill existed. Find candidate boundaries with:

```bash
git log --format='%ad %h %s' --date=short -- <base.md> <skill references>
```

Commit dates approximate activation. Label comparisons approximate unless a
retained system generation proves when the change went live.

## 3. Verify the extraction

Sample 40 rows from `prompts.jsonl` and confirm each is human-typed. A new
wrapper, hook injection, or relayed-report shape needs a pattern and a fixture
test in `history_audit.py` before its counts are trusted. Done when the sample
contains no injected or agent-authored text.

## 4. Read deterministic tables first

- `routing.md`: automatic, explicit, and missing loads per skill, agent, and
  window, plus whether a skill loaded before the first matching edit. High
  explicit shares mean the user types the skill by hand: an auto-routing gap.
- `phrases.md`: phrases typed across many sessions are standing preferences.
  They belong in a default, a skill, or a project `AGENTS.md`.
- `signals.md`: stall nudges, bare commit requests, pending-review and
  verification asks, and model switches per 100 prompts; gateway cooldowns and
  idle replies. Stall nudges that follow cooldowns are quota problems.

Keyword triggers are upper bounds; broad ones, such as Nix or error words,
overcount expected sessions.

## 5. Classify with workers

The run writes `digests/review-N.md` (review threads of at most 45 turns),
`digests/corrections-N.md` (non-review correction turns), and
`digests/orchestration-N.md` (longer threads). Spawn one read-only worker per
chunk with the matching packet from [rubrics.md](rubrics.md), naming the current
policy file so each complaint is marked covered, partial, or not covered with
line numbers. Split windows at the same boundaries.

## 6. Verify worker output

Search each quote you will cite in its digest with `rg -F`. Discard quotes from
relayed reports: pasted agent findings, `Direct answer:` blocks, severity keys,
or evidence packets. Cross-check each headline rate with a deterministic count,
such as a regex over follow-up turns. Done when every cited quote is a USER line
and every headline rate has a cross-check or a stated gap.

## 7. Synthesize

For each recurring complaint, record sessions per window, the rule that targets
it, and whether it persisted after that rule's date. A complaint that persists
after its prose rule needs a stronger owner. Route the fix to the first owner
that can enforce it:

1. A validator or guard in a skill script, for exact mechanics and destructive
   operations.
2. A deterministic provider hook, for a route that a provider ignores in prose.
3. A skill reference, for domain or branch behavior.
4. Shared base context, for cross-provider behavior that every task needs.

Send harness faults to the module that owns the harness.

## 8. Deliver

Lead with what persists after its rule, then what a change fixed, then harness
faults, then decisions. Implement defects and preferences the user already
stated; list preference calls as decisions. Persist durable lessons through
`okf-memory`. Keep the run directory for the next comparison or delete it; it
holds raw prompts.

## Harness logs outside the archive

- Claude `history.jsonl` under the config directory: rank the `display` values;
  automation that submits prompts shows as one value repeated thousands of
  times.
- Codex `logs_2.sqlite` under `CODEX_HOME`: rank ERROR and WARN rows by target.
- Per-launch log directories, such as Antigravity CLI `log/`: count files per
  day to catch polling loops.
- Transcript size: list session files above 200 MB and classify their largest
  tool outputs; inline screenshots inflate transcripts and archive rebuilds.
