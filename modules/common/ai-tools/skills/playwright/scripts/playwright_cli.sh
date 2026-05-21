#!/usr/bin/env -S nix shell nixpkgs#playwright-test --command bash
set -euo pipefail

exec playwright "$@"
