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

Context lives in three records. Durable local state holds the plan and lessons
already written down. Chat history holds what you did and decided. The shared
record holds what happened around the same code under other names: symptoms
users keep reporting, fixes that shipped and got reverted, errors still firing
in production. The `why` skill searches that third record across source control,
the issue tracker, chat and issue channels, long-form docs, and error tracking.
A feature with a long bug tail keeps most of its story there, so do not
reconstruct it from transcripts alone.

## Transcript stores

Transcript stores vary per provider. Claude Code writes one JSONL file per
session under its config directory at `projects/<slug>/`, where `<slug>` is the
workspace path with each `/` replaced by `-`. Every line is one chat message.
Discover the active provider's store before mining. Never read another project's
transcripts unless asked.

## Steps

1. Classify, then route. One specific prior chat to resume needs no fan-out;
   open that chat and read it directly. Turning habits into a durable skill is
   `skill-creator` work. A human-readable summary of your work is a different
   task. Recall loads working context across recent sessions before you act.
   When the user already gave a full state capsule (paths, branch, the change),
   use it and skip the mining.
2. Check durable local state before mining transcripts. Read active
   planning-with-files artifacts (`task_plan.md`, `findings.md`, `progress.md`)
   and `okf-memory` durable notes. These often answer "where did I leave off"
   with no transcript mining at all. When they answer the question, verify
   against live state and write the brief.
3. Lock the scope before searching. Pin the window ("recent" is a real range,
   default the last 7 days), the topic if named, and the workspace (default the
   active one). State the scope back. Never quietly turn "all" into "recent N".
4. Fan out across chat history. Spawn parallel read-only subagents on a fast,
   cheap model, each taking a slice of the corpus, because searching transcripts
   is grunt work. Tell every subagent to order candidates by real modification
   time (`ls -t`) and never by file name, grep the topic first, then read only
   the matching sessions and only their relevant regions, and skip the current
   session plus obvious noise (subagent, eval, and test sessions). Each returns
   the same schema, one block per session: topic, the user's goal, decisions,
   open threads, struggles and corrections, and artifacts (PRs, tickets,
   branches), each citing the session ID. For one or two sessions, skip the
   fan-out and search directly. Raw transcripts stay in the subagents. The main
   thread gets their findings only.
5. Sweep the shared record whenever the topic names a feature, file, subsystem,
   area, or bug. This is the default, not a judgment call, and "my work on X"
   does not exempt it. A named target carries history you never see in your own
   transcripts, and that history is the point of the sweep. Hand it to the `why`
   skill's source investigators, but steer their question from "why was this
   built this way" to "what is the current state, what has been tried and did
   not hold, and what are users still reporting". Reuse its per-source playbooks
   so you do not reinvent each query vocabulary. Run the investigators in
   parallel with the chat-history mining. Inherit its posture: one investigator
   per source, null results are findings, skip an unavailable MCP and say so.
   Fold the results into the brief. Skip this step only for pure activity recall
   with no named target ("what did I do this week"), where local state and chat
   history are the entire answer.
6. Verify against live state. A transcript or a stale ticket is history, not
   current truth. Take the PRs, branches, and tickets that the mining and the
   sweep surfaced, then check them with `git` and `gh`. When the answer hinges
   on what an agent actually did (the tools it ran, files it read, errors it
   hit), read the full transcript, not a trimmed local copy.
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
