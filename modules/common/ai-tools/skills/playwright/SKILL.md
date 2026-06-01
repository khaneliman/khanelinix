---
name: "playwright"
description: "Use when the task requires automating a real browser from the terminal (navigation, form filling, snapshots, screenshots, data extraction, UI-flow debugging) via the bundled Nix-backed Playwright wrapper script."
---

# Playwright CLI Skill

Drive a real browser from the terminal using the bundled wrapper script. The
wrapper provides Playwright from Nix, so it does not depend on `npx` or a
project-local Node install.
Treat this skill as CLI-first automation. Do not pivot to `@playwright/test`
unless the user explicitly asks for test files.

## Plays

- `references/setup.md`: skill path, wrapper check, Nix failure handling.
- `references/workflows.md`: practical flows and troubleshooting.
- `references/cli.md`: CLI command reference.
- `references/guardrails.md`: refs, artifacts, headed mode, eval/run-code.

## Required Setup

Read `references/setup.md`, export `PWCLI`, and run `"$PWCLI" --help`.

## Quick Start

Use the wrapper script:

```bash
"$PWCLI" open https://playwright.dev --headed
"$PWCLI" snapshot
"$PWCLI" click e15
"$PWCLI" type "Playwright"
"$PWCLI" press Enter
"$PWCLI" screenshot
```

## Core Workflow

1. Open the page.
2. Snapshot to get stable element refs.
3. Interact using refs from the latest snapshot.
4. Re-snapshot after navigation or significant DOM changes.
5. Capture artifacts (screenshot, pdf, traces) when useful.

Minimal loop:

```bash
"$PWCLI" open https://example.com
"$PWCLI" snapshot
"$PWCLI" click e3
"$PWCLI" snapshot
```

Read `references/workflows.md` for forms, traces, multi-tab work, and
troubleshooting. Read `references/guardrails.md` before using stale refs,
`eval`, `run-code`, headed mode, or repo artifacts.
