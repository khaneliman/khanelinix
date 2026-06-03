# Playwright CLI Setup

Use before first CLI action.

## Skill Path

`PWCLI` points at this skill's wrapper script. The skill is installed under your
harness's skills directory, e.g.:

```bash
# Claude Code
export PWCLI="$HOME/.claude/skills/playwright/scripts/playwright_cli.sh"
# Codex
export PWCLI="${CODEX_HOME:-$HOME/.codex}/skills/playwright/scripts/playwright_cli.sh"
```

## Prerequisite Check

No Node/npm/npx step is required. The wrapper execs `playwright-cli`
(`@playwright/cli`), provided by the `playwright-cli` package in this flake
(`pkgs.khanelinix.playwright-cli`) and installed via the home `common` suite.
It bundles nix-built, NixOS-runnable browsers, so no `playwright install` is
needed either.

```bash
"$PWCLI" --help
```

If you see `playwright-cli not found on PATH`, the package isn't installed —
ensure the home `common` suite is active (it adds
`pkgs.khanelinix.playwright-cli`), or run `playwright-cli` from
`nix run` against this flake.

## Browser

`open` defaults to the branded `chrome` channel upstream, which needs a system
Google Chrome. The package and skill wrapper transparently pass
`--browser chromium` for `open` unless you specify `--browser`, including when
session flags come first:

```bash
"$PWCLI" -s=design-review open http://127.0.0.1:4200/home
playwright-cli -s=design-review open http://127.0.0.1:4200/home
```

Do not enter a target repo's dev shell to fix browser paths. Use dev shells for
that repo's app server/toolchain only. Browser binaries come from this package.
Do not install browsers with `npx`/`npm` or `playwright install`.
