#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
usage: package-option-scan.sh <package-list-installable> [name-pattern]

Evaluates a NixOS/Home Manager option that is already a list of packages and
prints package names plus drv/out paths. This does not build the packages or
the full system closure.

example:
  package-option-scan.sh \
    .#nixosConfigurations.host.config.environment.systemPackages curl
USAGE
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    usage >&2
    exit 2
fi

installable="$1"
pattern="${2:-}"

nix eval --json --option eval-cache false --apply '
  pkgs:
    map
      (p: {
        name = p.name or "unknown";
        pname = p.pname or null;
        version = p.version or null;
        drvPath = p.drvPath or null;
      })
      pkgs
' "$installable" | jq --arg pattern "$pattern" '
  if $pattern == "" then
    .
  else
    map(select((.name // "") | test($pattern; "i")))
  end
'
