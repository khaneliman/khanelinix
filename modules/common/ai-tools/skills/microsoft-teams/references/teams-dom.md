# Teams page reference

Selectors for the Teams web client with an English UI. Prefer `data-tid`
attributes; English labels are listed where the script depends on them. Teams
changes its markup without notice, so recheck a selector against the live page
before concluding that data is missing.

Contents: [Views and selectors](#views-and-selectors) · [UI rules](#ui-rules) ·
[Open a search result in its thread](#open-a-search-result-in-its-thread) ·
[Output](#output)

## Views and selectors

| View          | Container                                       | Items and fields                                                                                                                                                |
| ------------- | ----------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| App bar       | `[data-tid=app-bar-wrapper]`                    | Buttons labeled `Activity (Ctrl+Shift+3)`, `Chat (Ctrl+Shift+4)`, and so on; tenant apps can come first                                                         |
| Sidebar       | `[role=treeitem][aria-level="1"]` groups        | `[aria-level="2"]` items; the first line of `innerText` is the name                                                                                             |
| Chat          | `[data-tid=message-pane-list-viewport]`         | `[data-tid=chat-pane-item]` holding `chat-pane-message`, `message-author-name` (first message of each run only), and `time[datetime]`                           |
| Channel posts | `[data-tid=channel-pane-viewport]`              | `[data-tid=channel-pane-message]` with `subject-line`, `[id^=author-]`, `message-body`, `response-summary-button` (opens replies), attachments                  |
| Thread        | `[data-tid=channel-replies-viewport]`           | `[data-tid=channel-replies-pane-message]`; the first item is the root post                                                                                      |
| Search        | `[data-tid=AUTOSUGGEST_INPUT]` (the search box) | `messages-tab`, `search-team-and-channel-filter` (In), `people-picker-search`, `[role=option]`, `search-filters`, `search-layout`, `search-card`, `Next` button |
| Call          | `[data-tid=call-duration]`                      | Present only while a call is active                                                                                                                             |

- Message wrappers carry `data-mid`, the creation time in epoch milliseconds.
  Replies also carry `data-reply-chain-id`, the root post's `data-mid`, which
  identifies the thread.
- Channel `time` elements carry the full date in `aria-label`; chat `time`
  elements carry an ISO `datetime`.
- File cards label themselves `name` and `name\nurl` through `aria-label`. Share
  and preview buttons have labels too, so keep only names with a file extension.
- Attachment URLs name the SharePoint site for `sp-list`: `/teams/<Site>/...`
  directly, or `/:w:/t/<Site>/...` in a sharing link, meaning `/teams/<Site>`.

## UI rules

- Teams can start on a tenant app such as a company portal.
  `Chat
  (Ctrl+Shift+4)` opens chats and reopens the last conversation, which
  marks it read.
- Open a conversation by clicking its sidebar item. From an open thread, the
  same channel's sidebar item does not return to the posts list, and the `Posts`
  header button is unreliable; reach threads through search or
  `cache-read --thread` instead.
- Lists are virtualized. To load older items, set `scrollTop` slightly down,
  back to 0, and dispatch a `wheel` event, repeating until `scrollHeight` holds.
  Then sweep in half-viewport steps, twice, keyed by `data-mid`.
- CDP `Input.insertText` and `Input.dispatchKeyEvent` go to whichever element
  has focus when they arrive, and focus can jump to a compose box. Set input
  values and dispatch keys on the target element inside the page, as the script
  does.
- Clicking an `[role=option]` in the In filter applies it at once; there is no
  Apply button. The picker shows a `Loading...` option before real matches. A
  new query clears the filter.
- Applied filters are mirrored into the search box text, for example
  `from:"Name" is:Messages in:Channel Name`.
- Results come in "Top results" followed by "All results", with the pager below.
  While a thread opened from search is showing, the pager is gone; rerun the
  search to get back.
- A window that is off screen or minimized renders no frames:
  `requestAnimationFrame` never fires and lazy loading stops, which cuts result
  lists short. CDP `Input.dispatchMouseEvent` can hang on Wayland compositors;
  scroll by setting `scrollTop`.

## Open a search result in its thread

Use this when the cache lacks the conversation and the user needs a whole
thread. Opening the thread marks it read, so name it to the user first.

1. Run `status` and continue only with `inCall: false` and `rendering: true`;
   `eval` skips those checks.
2. Run `search` so the results stay on screen.
3. Save this script, replacing the phrase with text from the target message, and
   run `teams_cdp.mjs eval @open-result.js`. It returns the message id and
   thread id.
4. Run `read --all` to read the thread.

```js
(async () => {
  const phrase = /Distinctive phrase/;
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const card = [...document.querySelectorAll("[data-tid=search-card]")]
    .find((c) => phrase.test(c.innerText));
  if (!card) return { error: "card not on this page" };
  const leaf = [...card.querySelectorAll("*")]
    .find((e) => e.children.length === 0 && phrase.test(e.textContent));
  (leaf ?? card).click();
  for (let i = 0; i < 40; i++) {
    await sleep(700);
    const m = [
      ...document.querySelectorAll("[data-tid=channel-replies-pane-message]"),
    ]
      .find((m) => phrase.test(m.innerText));
    if (m) {
      const w = m.querySelector("[data-reply-chain-id]");
      return { mid: w?.dataset.mid, replyChainId: w?.dataset.replyChainId };
    }
  }
  return { error: "message not found in thread" };
})();
```

A card on a results page that has not loaded returns `card not on this page`;
page forward and retry. A top-level post may open in the channel view instead of
a thread and return `message not found in thread`.

## Output

Truncate strings by code point with `Array.from(s).slice(0, n).join('')`.
Slicing by index can split an emoji's surrogate pair, which makes `jq` reject
the JSON.
