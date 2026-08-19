# Flake Maintenance

## Inspect Inputs

```bash
nix flake metadata
nix flake metadata --json | jq '.locks.nodes | keys | length'
nix flake metadata --json | jq -r '.locks.nodes | to_entries[] | [.key, .value.locked.type, .value.locked.owner, .value.locked.repo, .value.locked.rev] | @tsv'
nix flake show
```

## Update Inputs

```bash
nix flake update input-name   # one input
nix flake update              # all inputs
```

After updates, inspect `flake.lock` and run the narrowest relevant build or
eval.

## Temporary Overrides

```bash
nix build .#package --override-input nixpkgs github:NixOS/nixpkgs/nixos-unstable
nix flake metadata --override-input nixpkgs path:/path/to/nixpkgs
nix flake metadata github:owner/repo --inputs-from .   # evaluate another flake with current repo's pins
```

## Follows Checks

Check duplicate nixpkgs-like inputs before/after a follows change:

```bash
nix flake metadata --json \
  | jq -r '.locks.nodes | to_entries[] | select(.value.locked.repo? == "nixpkgs") | [.key, .value.locked.rev] | @tsv' \
  | sort
```

Validate cache-hit tradeoffs before broad follows changes.

## Cache and Substitution

```bash
out="$(nix eval --raw nixpkgs#hello.outPath)"
nix path-info --store https://cache.nixos.org/ "$out"
nix build .#package --dry-run
nix build .#package --dry-run --refresh   # when metadata may be stale
```

Resolve installable to store path before querying remote binary cache.

## Lockfile Tips

- Compare lockfile by input name and revision, not JSON line count.
- Node count increase → inspect input graph duplication.
- Broad follows changes can hurt binary cache hits for large upstream projects.
- Verify at least one affected system/package after lock updates; metadata-only
  checks don't prove builds work.

## Reporting Checklist

- Inputs changed, lockfile node count changes.
- Builds/evals run after update.
- Cache-hit risk from follows or input pin changes.
