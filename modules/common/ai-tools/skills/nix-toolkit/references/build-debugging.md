# Build Debugging

## Triage Order

1. Reproduce with narrowest target.
2. Collect failing log.
3. Inspect derivation/builder environment only as needed.
4. Patch or adjust inputs.
5. Rebuild same target.

## Core Commands

```bash
nix build .#package
nix log .#package
nix derivation show .#package
nix path-info .#package
```

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

## Patch Debugging

- Prefer `substituteInPlace` over ad-hoc `sed`.
- Use `--replace-fail` so source drift fails loudly.
- For upstream patch URLs, prefer `fetchpatch2`.
- Start fixed-output patch hashes with `lib.fakeHash`; copy the `got:` SRI hash
  from the failure.

## Reporting Checklist

- Target, failing phase, exact error excerpt.
- Relevant derivation fields (if inspected).
- Suspected cause, minimal proposed change, verification command.
