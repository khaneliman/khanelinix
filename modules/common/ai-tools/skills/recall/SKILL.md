---
name: recall
description: "Reconstruct recent working context from local plans, memory, transcripts, and the shared record into a current-state brief. Use for 'recall my work on X', 'catch me up', 'what have I been working on', or 'where did I leave off'."
---

# Recall

Rebuild the user's recent working context before starting or resuming work. Hand
back a capsule of where things stand now and what to do next.

Keep the sweep tight and on-topic. Read only what the in-scope threads need,
then stop. Fan the heavy reading out to parallel read-only subagents. The main
thread keeps their findings and the final brief.

Context lives in three records: durable local state (the plan and lessons
already written down), chat history (what you did and decided), and the shared
record (what happened around the same code under other names).

## Steps

1. Classify, then route. One specific prior chat to resume needs no fan-out;
   open that chat and read it directly. Turning habits into a durable skill is
   `skill-creator` work. When the user already gave a full state capsule
   (paths, branch, the change), use it and skip the mining.
2. Check durable local state before mining transcripts. Read active
   planning-with-files artifacts (`task_plan.md`, `findings.md`, `progress.md`)
   and `okf-memory` durable notes. When they answer the question, verify
   against live state and write the brief.
3. Lock the scope before searching. Pin the window ("recent" is a real range,
   default the last 7 days), the topic if named, and the workspace (default the
   active one). State the scope back. Never quietly turn "all" into "recent N".
4. Fan out across chat history. Read
   [chat-mining.md](references/chat-mining.md) for the store layout, the
   subagent instructions, and the findings schema.
5. Sweep the shared record when the topic names a feature, file, subsystem,
   area, or bug. Read [shared-record.md](references/shared-record.md) for the
   default rule, the `why` handoff, and the question to steer.
6. Verify against live state. A transcript or a stale ticket is history, not
   current truth. Check the PRs, branches, and tickets the mining and the sweep
   surfaced with `git` and `gh`.
7. Write the brief to the contract below. Group by thread. Stay on the named
   topic.

## Output contract

Lead with the capsule, then thread status, then problems, then the next move.
Put deeper detail below or cut it.

- **Capsule.** At most 5 bullets. What this work is and where it stands overall.
- **Threads.** One line each, prefixed with exactly one status tag:
  `[merged #N]`, `[open PR #N]`, `[in flight <branch>]`,
  `[verified, uncommitted]`, `[reverted #N]`, or `[planned, not started]`. An
  untagged thread is not done, so tag it.
- **Problems.** At most 5, the recurring ones. Include the symptoms users keep
  reporting and any fix that shipped and was reverted, so the next attempt
  starts where the last one failed.
- **Next move.** The single most useful next action, concrete.

Leave an adjacent feature or ticket out unless it blocks this one. When the
capsule and thread lines outgrow a screen, cut detail before you cut threads.
Write the brief through the `unslop` skill. Cite chat findings by session ID and
shared-record findings by their source (PR number, ticket ID, chat permalink,
error-tracker issue). Sanitize private context before any public output.

**Reply:** the brief, to the contract above.
