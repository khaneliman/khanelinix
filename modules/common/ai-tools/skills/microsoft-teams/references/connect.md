# Connecting to Teams

## 1. Use supported access when the tenant allows it

These routes go through Microsoft Graph and need tenant approval. Try them
first, and stop at the first tenant block. Never sign in with another
application's client ID to get past an assignment or consent block.

| Route                                                                            | Requires                                                                                                         |
| -------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| Microsoft's Work IQ Teams MCP server (Agent 365)                                 | Microsoft 365 Copilot license and an admin-registered, admin-consented app                                       |
| Claude's Microsoft 365 connector                                                 | A Claude org owner enables it; an Entra Global Administrator consents for the organization                       |
| Community [`@floriscornel/teams-mcp`](https://github.com/floriscornel/teams-mcp) | Users may sign in to Microsoft Graph Command Line Tools and consent to `Chat.Read` and `ChannelMessage.Read.All` |

Sign-in errors:

- `AADSTS50105`: the tenant requires assignment to the app. Only an admin can
  grant it; fall back to the client routes below.
- `AADSTS9002313` from the Azure CLI: it needs an interactive
  `az login --scope https://graph.microsoft.com/.default`.

Check for an Azure CLI Graph token without printing it:
`az account get-access-token --resource https://graph.microsoft.com --query expiresOn -o tsv`.
`@floriscornel/teams-mcp` keeps a plaintext refresh token in
`~/.teams-mcp-token-cache.json` and status in `~/.msgraph-mcp-auth.json`; delete
both after a trial.

## 2. Attach to teams-for-linux

`teams-for-linux` wraps the Teams web app in Electron and accepts Chromium
switches. This route is exercised end to end; the others below are not.

1. Run `status`. A listening port is what counts; a leftover
   `DevToolsActivePort` file in the Teams config directory proves nothing.
2. Ask the user before restarting Teams, because a restart ends calls.
3. Stop the main process, whose command line ends in `app.asar`
   (`pgrep -af 'teams-for-linux.*app\.asar'`), with `kill -TERM <pid>`. Wait
   until no `teams-for-linux` processes remain.
4. Relaunch it detached, bound to localhost, with a private log:

   ```sh
   log="${XDG_CACHE_HOME:-$HOME/.cache}/teams-cdp/teams.log"
   mkdir -p -m 700 "${log%/*}"
   setsid -f teams-for-linux --remote-debugging-port=9222 \
     --remote-debugging-address=127.0.0.1 >"$log" 2>&1 </dev/null
   ```

5. Poll `status` until it reports the Teams page; first render can take a
   minute.

The port closes when Teams restarts. To make it permanent, the user can set
`"performance": { "electronCLIFlags": [["remote-debugging-port", "9222"]] }` in
the teams-for-linux `config.json`. Each entry is passed to Electron's
`app.commandLine.appendSwitch`, so it needs the name without `--` and the value
as a separate item; a flat `"--remote-debugging-port=9222"` string is ignored.
Leave this choice to the user: an open port lets any local process act as the
signed-in account.

## 3. Teams web in a Chromium browser

Start a dedicated profile with the debug port and have the user sign in once:

```sh
chromium --remote-debugging-port=9222 \
  --user-data-dir="${XDG_DATA_HOME:-$HOME/.local/share}/teams-cdp-profile" \
  https://teams.cloud.microsoft/
```

Chrome 136 and later ignore the debug switches on the default profile, so the
dedicated `--user-data-dir` is required
([Chrome announcement](https://developer.chrome.com/blog/remote-debugging-port)).
Use this route on macOS as well.

## 4. New Teams on Windows

New Teams renders in Microsoft Edge WebView2, which reads extra Chromium
switches from `WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS`
([WebView2 browser flags](https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/webview-features-flags)).
Set it to `--remote-debugging-port=9222` only for the Teams launch, because it
applies to every WebView2 app started from that environment. Elevated apps
ignore it, and tenant policy may block it.

## Not useful

Capturing network traffic exposes no usable chat API; Teams reads messages from
its local cache through workers. Copying tokens out of the page is never
allowed.
