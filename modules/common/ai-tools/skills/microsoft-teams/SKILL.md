---
name: microsoft-teams
description: Read and search Microsoft Teams chats, channel threads, and channel files through the user's signed-in Teams client over the Chrome DevTools Protocol, without a Teams MCP server or Graph access. Use when the user needs Teams messages, someone's posts in a channel, thread replies, or channel files.
---

# Microsoft Teams

Read Teams through the user's signed-in client over the Chrome DevTools Protocol
(CDP). The client's session does the authentication, so no tokens, Graph
permissions, or admin consent are involved. Run every command as
`node <skill-dir>/scripts/teams_cdp.mjs <command>` (Node 22+); without arguments
it prints usage and exit codes.

## Rules

- Read only. Send, react, edit, or delete only when the user asks.
- Never print, store, or extract tokens or cookies. Make requests from inside
  the signed-in page or frame.
- Ask before restarting Teams; a restart ends calls.
- Keep exports in a private directory outside the skill, such as
  `${XDG_CACHE_HOME:-$HOME/.cache}/teams-export` with mode 700.
- UI commands (`search`, `read`, `sidebar`) need the window handed over: on
  screen, no call, nobody typing. Opening a conversation marks it read, so name
  it to the user first. One agent drives the UI at a time.

## Workflow

1. **Check access.** Use a working Teams MCP server or Graph access instead of
   this skill. Otherwise run `status`; exit 3 means no debug endpoint or Teams
   page, so follow [references/connect.md](references/connect.md).
2. **Find the conversation.** `cache-list --kind channel --name Design` lists
   matching conversations with their ids and teams.
3. **Read the cache.** `cache-read "<name-or-id>" --from self` returns cached
   messages. This step is done when the output covers the request, or when it
   returns a `hint` or stops short of the dates needed.
4. **Search for the rest.** `search '<query>' --in "<conversation>"` covers
   history the cache lacks. On exit 5 (call) or 6 (window off screen), wait for
   the user and retry.
5. **Read an open view** only for content neither source returns: open the
   conversation, then `read` or `read --all`.
6. **Fetch files.** `sp-download <private-dir> <path>` takes the attachment
   paths from `cache-read` or files listed by `sp-list /teams/<Site>`.

## Cache commands

The cache commands read Teams' IndexedDB. They never touch the UI, mark nothing
read, and work while the window is hidden.

- `cache-list` returns id, kind, name, and team for each conversation. Filter
  with `--kind` (chat, channel, meeting, community, other), `--name`, and
  `--team`.
- `cache-read <name-or-id>` returns messages oldest first: id, `threadId`,
  `isRoot`, time, author, subject, and attachments with SharePoint `path`s.
  Filters: `--from self|"Display Name"`, `--thread ID`, `--since` and `--until`
  (ISO), `--limit` (default 500, newest kept), `--all-types` for call records.
  `--body` adds text, capped by `--max-chars` (default 4000).
- A name that matches nothing or several conversations exits 4 and lists
  candidates. Every team has a General channel; add `--team` or use the id.
- Results are what this client has synced. Most conversations have nothing
  cached, and cached ones usually hold recent history only, so `completeness` is
  always `unknown`. Deleted messages are skipped and counted.

Schema and limits: [references/cache.md](references/cache.md).

## UI search

- `--in` scopes to one chat or channel; without it, search spans every
  conversation. A new query clears the filter, so the script reapplies it.
- `from:"Name"` limits results to one sender. Option labels list the channel and
  then its team; `--team TEXT` picks among same-named channels.
- Each page holds up to 25 cards. The script follows Next up to `--max-pages`
  (default 10) and sets `more: true` when it stops early.
- Counts are a lower bound. Cards carry no thread id; use `cache-read` for
  thread ids.

## Open views and files

- `read` returns the messages loaded in the open chat, channel, or thread.
  `read --all` scrolls a channel or thread toward its start; its `settledAtTop`
  flag means loading stopped, not that the first message was reached.
- `sp-list /teams/<Site>` lists library files with author and times.
  `sp-download` writes mode-600 files under the output directory, refuses to
  overwrite without `--force`, and exits 1 if any download fails.
- Convert `.docx` with `pandoc -f docx -t gfm`; for `.pptx`, join the `<a:t>`
  runs in each `ppt/slides/slideN.xml`.
- `eval` runs JavaScript in the page or a `--target <url-regex>` frame and skips
  every guard. Selectors and UI quirks:
  [references/teams-dom.md](references/teams-dom.md).

Unverified: `read --all`, `--team`, in-page search submission, and sending.
