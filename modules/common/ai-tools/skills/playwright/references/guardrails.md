# Playwright CLI Guardrails

Use when interacting by element refs or capturing artifacts.

## Element Refs

- Always snapshot before referencing ids like `e12`.
- Snapshot again after navigation, DOM changes, modals/menus, tab switches, or
  failed missing-ref command.
- If no fresh snapshot exists, use placeholder refs like `eX` and say why.
- Do not bypass stale refs with `run-code`.

## Command Choice

- Prefer explicit commands over `eval` and `run-code`.
- Use `--headed` when visual inspection helps.
- Default to CLI commands and workflows, not Playwright test specs.

## Artifacts

In this repo, write Playwright artifacts under `output/playwright/`. Avoid new
top-level artifact directories.
