# Chat-history mining

Transcript stores vary per provider. Claude Code writes one JSONL file per
session, one chat message per line, under its config directory at
`projects/<slug>/`, `<slug>` being the workspace path with `/` replaced by `-`.
Discover the active provider's store before mining. Never read another project's
transcripts unless asked.

For one or two sessions, skip the fan-out and search directly. Otherwise spawn
parallel read-only subagents on a fast, cheap model, each taking a slice of the
corpus. Raw transcripts stay in the subagents. The main thread gets their
findings only.

Tell every subagent to:

- order candidates by real modification time (`ls -t`), never by file name;
- grep the topic first, then read only the matching sessions and only their
  relevant regions;
- skip the current session plus obvious noise (subagent, eval, and test
  sessions);
- return the same schema, one block per session: topic, the user's goal,
  decisions, open threads, struggles and corrections, and artifacts (PRs,
  tickets, branches), each citing the session ID.

When the answer hinges on what an agent actually did (the tools it ran, files
it read, errors it hit), read the full transcript, not a trimmed local copy.
