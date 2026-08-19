---
name: reflect
description: "Mine the session transcript with three review lenses and route durable learnings into skill edits or memory notes. Use when the user says reflect, after a complex task lands cleanly, or after a correction or new workflow worth keeping."
---

# Reflect

Mine the current conversation for durable learnings. Route each learning into a
skill edit or a durable memory note.

## When To Invoke

- The user said "reflect".
- A complex task of 5 or more tool calls landed cleanly and the recipe is worth
  keeping.
- The agent hit dead ends, found the working path, and the path generalizes.
- The user corrected the agent's approach mid-task.
- A non-trivial workflow emerged that no skill captures.

Skip trivial or off-topic conversations. Skip work an existing skill already
covers and the parent followed correctly. One-offs are not learnings.

## Workflow

### 1. Locate the Active Transcript

Find the transcript for the current session before you fan out. Follow
[transcript-location.md](references/transcript-location.md), and list candidates
only from the current workspace so private sessions from other projects stay
unread. If no path resolves, write a tight digest of the session and pass the
digest instead.

### 2. Spawn Three Reviewers in Parallel

Launch three reviewer subagents in one message. Use distinct model families when
the harness offers them. Reviewers need MCP access to look up context the
transcript cites, so do not run them read-only. Each prompt forbids file writes;
the parent applies every edit.

| Lens      | Prompt template                                           |
| --------- | --------------------------------------------------------- |
| Judgment  | [judgment-reviewer.md](references/judgment-reviewer.md)   |
| Tooling   | [tooling-reviewer.md](references/tooling-reviewer.md)     |
| Divergent | [divergent-reviewer.md](references/divergent-reviewer.md) |

Pass each template verbatim. Substitute the transcript path or the digest where
the template marks it. Reviewers return findings in the subagent response.

### 3. Synthesize

Spawn one synthesizer subagent with [synthesizer.md](references/synthesizer.md)
verbatim. Inline each reviewer's full output where the template marks it. The
synthesizer spot-verifies citations, so it also needs MCP access. It returns a
structured Accepted, Rejected, and Backlog list.

### 4. Structural Enforcement Check

Sanity-check the synthesizer's Accepted list. Move an item to Backlog when a
lint rule, script, metadata flag, or runtime check enforces it more reliably
than prose, per the encode-lessons-in-structure principle in
`engineering-principles`. This pass runs last, before edits land.

### 5. Apply

Present the synthesizer's full Accepted, Rejected, and Backlog output to the
user. Wait for explicit approval before you apply any Accepted edit. The user
picks the subset to apply and may redirect routings. Skill changes affect every
future session, so never auto-apply.

Backlog items and durable learnings that are not skill edits route to the
`okf-memory` skill. Only the Accepted list waits for approval.

Land every skill edit in the canonical tree `modules/common/ai-tools/skills/` in
the khanelinix repository, never in deployed provider copies under user config.
Without the canonical checkout, file the learning as an `okf-memory` note
instead.

For each approved Accepted item, follow the Routing field exactly:

- Trivial existing-skill edit, such as one bullet, a tightened sentence, or a
  stale fact: the parent edits the canonical skill directly.
- Substantive existing-skill edit, such as a new section, a new pattern table,
  or more than about 10 lines: hand to the `skill-creator` skill and run its
  draft, test, and iterate loop.
- `tune description: <skill path>` when the skill exists but did not trigger:
  hand to `skill-creator` and run its description-tuning loop.
- `new skill via skill-creator: <kebab-name>`: hand creation to `skill-creator`.
  Do not invent the package shape ad hoc.

After skill edits, run the skill test runner on the canonical tree:
`python3 modules/common/ai-tools/skills/ai-tools-architect/scripts/run_skill_tests.py`.

### 6. Summarize for the User

Short list, no preamble:

- Edits applied: `<skill path>`. What changed, one line each.
- New skills created: `<skill path>`. One line each. Rare.
- Notes filed to `okf-memory`: `<note title>`. One line each.
- Dropped: one line per rejected finding plus the synthesizer's reason.
