# Teams client cache

Microsoft does not document this schema, and it can change with any Teams
release. When `cache-list` or `cache-read` fails or returns odd shapes, inspect
the stores again before trusting the output.

## What the commands read

Teams keeps about a hundred IndexedDB databases named
`Teams:<manager>:react-web-client:<tenant>:<user>:<locale>`. The commands open
only these three, read-only, at their current version:

| Database               | Store           | Key                              | Used for                        |
| ---------------------- | --------------- | -------------------------------- | ------------------------------- |
| `conversation-manager` | `conversations` | `id`                             | Names, kinds, and team links    |
| `replychain-manager`   | `replychains`   | `[conversationId, replyChainId]` | One record per thread           |
| `profiles`             | `profiles`      | not relied on                    | Display name to sender id (MRI) |

Other databases hold calls, apps, activity, and authentication state. Keep any
extension to named stores and allowlisted fields, and never read databases,
stores, or fields whose names suggest auth, tokens, credentials, or sessions.
More than one database per manager means several signed-in accounts; the
commands then exit 4 rather than guess.

## Conversation names

| Record                                   | Kind               | Name                                                                | Team                                   |
| ---------------------------------------- | ------------------ | ------------------------------------------------------------------- | -------------------------------------- |
| `Chat`                                   | chat               | `threadProperties.topic`, else participants (`chatTitle.longTitle`) | none                                   |
| `Space` without `parentId`               | channel            | `topicThreadTopic` (the General channel)                            | its own `spaceThreadTopic`             |
| `Topic` (standard channel)               | channel            | `topicThreadTopic`                                                  | `teamId` record's `spaceThreadTopic`   |
| `Space` with `parentId` (shared/private) | channel            | `spaceThreadTopic`                                                  | `parentId` record's `spaceThreadTopic` |
| `Meeting`, `EngageCommunity`             | meeting, community | `threadProperties.topic`                                            | none                                   |

Every team has a channel named General, so pass `--team` or an id for those.

## Messages

Each `replychains` record holds one thread in `messageMap`. A thread root has
`id` equal to the record's `replyChainId`. Fields the script uses:

- `id`, `parentMessageId`, `creator` (an MRI such as `8:orgid:<guid>`),
  `originalArrivalTime` (epoch milliseconds), `isSentByCurrentUser`,
  `imDisplayName`.
- `messageType`: `RichText/Html` and `Text` are ordinary messages. Call
  recordings (`RichText/Media_CallRecording`), transcripts
  (`RichText/Media_CallTranscript`), and call events (`Event/Call`) are skipped
  unless `--all-types` is passed.
- `content`: HTML for `RichText/Html`. Teams enforces Trusted Types, so
  `DOMParser` and `innerHTML` reject plain strings; `--body` strips tags and
  decodes entities instead, which loses table layout.
- `properties.subject` for channel post titles; `properties.deletetime` on
  deleted messages, which are skipped and counted.
- `properties.files`: a JSON array whose entries carry `fileName`, `fileType`,
  and `fileInfo.fileUrl` or `fileInfo.serverRelativeUrl`. The script turns those
  into server-relative paths that `sp-download` accepts.

## Coverage and limits

- The cache holds what this client has synced, not the server's history. Most
  conversations have no cached messages, and cached ones usually hold only
  recent history. Teams does not document which conversations it caches.
- `cache-read` returns a `hint` when a conversation has nothing cached. Treat
  missing messages as unknown, not absent, and use `search` for them.
- Entries can lag the server or be evicted.
- Reads are fast enough to run freely: a scoped query takes tens of milliseconds
  in the page and needs no rendering, so it works with the window hidden.
