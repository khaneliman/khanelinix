# Playwright CLI Workflows

Use the wrapper script and snapshot often. Assume `PWCLI` is set and `pwcli` is
an alias for `"$PWCLI"`. In this repo, run commands from
`output/playwright/<label>/` to keep artifacts contained.

Start target app servers with their project tooling or dev shell, but run
browser automation through `pwcli` or packaged `playwright-cli`. Do not use
`nix develop -c playwright-cli` as a browser-path workaround.

## Standard interaction loop

```bash
pwcli open https://example.com
pwcli snapshot
pwcli click e3
pwcli snapshot
```

## Form submission

```bash
pwcli open https://example.com/form --headed
pwcli snapshot
pwcli fill e1 "user@example.com"
pwcli fill e2 "password123"
pwcli click e3
pwcli snapshot
pwcli screenshot
```

## Data extraction

```bash
pwcli open https://example.com
pwcli snapshot
pwcli eval "document.title"
pwcli eval "el => el.textContent" e12
```

## Debugging and inspection

Capture console messages and network activity after reproducing an issue:

```bash
pwcli console warning
pwcli requests
```

Record a trace around a suspicious flow:

```bash
pwcli tracing-start
# reproduce the issue
pwcli tracing-stop
pwcli screenshot
```

## Sessions

Use sessions to isolate work across projects:

```bash
pwcli --session marketing open https://example.com
pwcli --session marketing snapshot
pwcli --session checkout open https://example.com/checkout
playwright-cli -s=design-review open http://127.0.0.1:4200/home
```

Or set the session once:

```bash
export PLAYWRIGHT_CLI_SESSION=checkout
pwcli open https://example.com/checkout
```

## Configuration file

By default, the CLI reads `playwright-cli.json` from the current directory. Use
`--config` to point at a specific file.

Minimal example:

```json
{
  "browser": {
    "launchOptions": {
      "headless": false
    },
    "contextOptions": {
      "viewport": { "width": 1280, "height": 720 }
    }
  }
}
```

## Troubleshooting

- If an element ref fails, run `pwcli snapshot` again and retry.
- If the page looks wrong, re-open with `--headed` and resize the window.
- If a flow depends on prior state, use a named `--session`.
