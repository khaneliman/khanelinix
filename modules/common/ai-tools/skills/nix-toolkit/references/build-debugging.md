# Build Debugging

## Triage Order

1. Reproduce with narrowest target.
2. Collect failing log.
3. Inspect derivation/builder environment only as needed.
4. Patch or adjust inputs.
5. Rebuild same target.

## Core Commands

```bash
nix build .#package -L
nix log .#package
nix derivation show .#package
nix path-info .#package
```

Pass `-L` (or `--print-build-logs`) to `nix build` during iterative debugging.
It streams builder output directly to the terminal, showing failure context at
the exact failing line. This beats the `nix log` round trip when reproducing a
failure or when an intermediate derivation build fails before top-level
completion. Reserve `nix log` for inspecting already-completed builds or remote
failures.

Legacy: `nix-build -A package && nix log result`

## Derivation-First Debugging

```bash
nix derivation show .#package | jq '.derivations | to_entries[0].value | {
  builder,
  system,
  args,
  env: {
    name: .env.name,
    version: .env.version,
    src: .env.src,
    patches: .env.patches,
    configureFlags: .env.configureFlags,
    cmakeFlags: .env.cmakeFlags
  }
}'
```

Use `--recursive` only when dependency derivations matter; it is noisy.

## Build Flags

```bash
nix build .#package --no-link          # no result symlink
nix build .#package --keep-failed      # retain temp dir on failure
nix build .#package --rebuild --no-link  # bypass cached substitute
```

## Log Fallback

If `nix log .#package` cannot resolve the failing drv:

```bash
drv="$(nix build .#package --derivation --no-link --print-out-paths)"
nix log "$drv"
```

## Fixed-Output Hash Mismatch

When a build fails with:

```text
error: hash mismatch in fixed-output derivation '<store-path>':
  specified: sha256-...
  got:    sha256-...
```

Seeing this error during a build you did not expect to fetch indicates that an
upstream source archive or release tag changed in place, an ecosystem lockfile
(such as `Cargo.lock`, `go.mod`, or `package-lock.json`) drifted without
updating its corresponding derivation hash (`cargoHash`, `vendorHash`, or
`npmDepsHash`), or an unexpected fixed-output derivation dependency is pulling
remote assets.

For the workflow to derive and update the expected hash using `lib.fakeHash`,
see [Fixed-Output Hashes](packages-and-overlays.md#fixed-output-hashes).

## Patch Debugging

- Prefer `substituteInPlace` over ad-hoc `sed`.
- Use `--replace-fail` so source drift fails loudly.
- For upstream patch URLs, prefer `fetchpatch2`.
- Start fixed-output patch hashes with `lib.fakeHash`; copy the `got:` SRI hash
  from the failure.
- `fetchpatch2` runs `filterdiff -p1 -x <exclude>`, so an `excludes` pattern
  matches the path with the `a/` prefix already stripped. Reproduce an exclude
  locally with the same `-p1`; without it the pattern misses and the excluded
  hunk stays in the patch.
- Reproduce the build's `patch -p1` behavior, not `git apply`, which is stricter
  and reports failures the build never sees.

## Reporting Checklist

- Target, failing phase, exact error excerpt.
- Relevant derivation fields (if inspected).
- Suspected cause, minimal proposed change, verification command.
