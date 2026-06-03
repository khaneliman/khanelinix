#!/usr/bin/env bash
set -euo pipefail

# Thin wrapper around @playwright/cli (bin: playwright-cli), provided by the
# `playwright-cli` package in this flake (pkgs.khanelinix.playwright-cli) and
# installed via the home `common` suite. The package bakes in nix-built,
# NixOS-runnable browsers via PLAYWRIGHT_BROWSERS_PATH.
if ! command -v playwright-cli >/dev/null 2>&1; then
  echo "playwright-cli not found on PATH." >&2
  echo "Enable pkgs.khanelinix.playwright-cli (home 'common' suite installs it)." >&2
  exit 127
fi

# Upstream `open` defaults to the branded 'chrome' channel, which expects a
# system Google Chrome install. Default to the nix-provided Chromium instead,
# including when global flags such as `-s=name` come before `open`.
has_browser=0
command_index=0
command_name=
skip_next=0
index=0

for arg in "$@"; do
  index=$((index + 1))

  case "$arg" in
  --browser | --browser=* | -browser | -browser=*) has_browser=1 ;;
  esac

  if [ "$command_index" -ne 0 ]; then
    continue
  fi

  if [ "$skip_next" -eq 1 ]; then
    skip_next=0
    continue
  fi

  case "$arg" in
  -s | --session)
    skip_next=1
    ;;
  -s=* | --session=* | --*)
    ;;
  -*)
    ;;
  *)
    command_index=$index
    command_name=$arg
    ;;
  esac
done

if [ "$command_name" = open ] && [ "$has_browser" -eq 0 ]; then
  set -- "$@" --browser chromium
fi

exec playwright-cli "$@"
