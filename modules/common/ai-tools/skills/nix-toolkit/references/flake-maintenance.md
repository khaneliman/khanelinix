# Flake Maintenance

Use this playbook for flake lock updates, input graph inspection, follows
cleanup, and cache behavior.

## Inspect Inputs

```bash
nix flake metadata
nix flake metadata --json | jq '.locks.nodes | keys | length'
nix flake metadata --json | jq -r '.locks.nodes | to_entries[] | [.key, .value.locked.type, .value.locked.owner, .value.locked.repo, .value.locked.rev] | @tsv'
nix flake show
```

## Update Inputs

Update one input:

```bash
nix flake update input-name
```

Update all inputs:

```bash
nix flake update
```

After updates, inspect `flake.lock` and run the narrowest relevant build or
eval.

## Temporary Overrides

Use overrides for investigation without committing lockfile changes:

```bash
nix build .#package --override-input nixpkgs github:NixOS/nixpkgs/nixos-unstable
nix flake metadata --override-input nixpkgs path:/path/to/nixpkgs
```

Use `--inputs-from` when evaluating another flake with the current repo's input
pins:

```bash
nix flake metadata github:owner/repo --inputs-from .
```

## Follows Checks

Use `inputs.<name>.follows = "nixpkgs";` when it safely reduces duplicate input
graphs. Validate cache-hit tradeoffs before broad follows changes.

Check duplicate nixpkgs-like inputs before and after a follows change:

```bash
nix flake metadata --json \
  | jq -r '.locks.nodes | to_entries[] | select(.value.locked.repo? == "nixpkgs") | [.key, .value.locked.rev] | @tsv' \
  | sort
```

## Cache and Substitution Checks

```bash
out="$(nix eval --raw nixpkgs#hello.outPath)"
nix path-info --store https://cache.nixos.org/ "$out"
nix build .#package --dry-run
```

Resolve an installable to a store path before querying a remote binary cache.
Use `--dry-run` to distinguish local build work from substitutable paths.

Use `--refresh` when metadata may be stale:

```bash
nix build .#package --dry-run --refresh
```

## Lockfile Review Tips

- Compare lockfile changes by input name and revision, not JSON line count.
- Treat `flake.lock` node count increases as a signal to inspect input graph
  duplication.
- Avoid broad follows changes when they reduce source builds but hurt binary
  cache hits for large upstream projects.
- Verify at least one affected system/package after lock updates; metadata-only
  checks do not prove builds still work.

## Reporting Checklist

- Inputs changed.
- Lockfile node count or notable graph changes when relevant.
- Builds/evals run after update.
- Any cache-hit risk from follows or input pin changes.
