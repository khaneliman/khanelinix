# Build Debugging

Use this playbook for failed Nix builds, missing outputs, suspicious patches, or
derivation inspection.

## Triage Order

1. Reproduce with the narrowest target.
2. Collect the failing log.
3. Inspect the derivation and builder environment only as needed.
4. Patch or adjust inputs.
5. Rebuild the same target.

## Core Commands

```bash
nix build .#package
nix log .#package
nix derivation show .#package
nix path-info .#package
```

For legacy attributes:

```bash
nix-build -A package
nix log result
```

## Derivation-First Debugging

Use this when the failure is caused by inputs, phases, environment variables, or
builder arguments rather than compiler output:

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

Use `nix derivation show --recursive .#package` only when dependency derivations
matter; it can be noisy.

## Build Without Linking

Use this for quick verification that should not disturb `result` symlinks:

```bash
nix build .#package --no-link
```

## Keep Failed Build Directories

Use when logs are insufficient and local build artifacts matter:

```bash
nix build .#package --keep-failed
```

Then inspect the printed temporary directory.

## Rebuild Despite Substitutes

Use this when checking whether a cached output masks local nondeterminism or a
machine-specific failure:

```bash
nix build .#package --rebuild --no-link
```

## Log Fallbacks

If `nix log .#package` cannot resolve the failing derivation, build the drv path
first and log that:

```bash
drv="$(nix build .#package --derivation --no-link --print-out-paths)"
nix log "$drv"
```

## Patch Debugging

- Prefer `substituteInPlace` over ad-hoc `sed` inside derivations.
- Prefer `--replace-fail` when replacing text so source drift fails loudly.
- For upstream patch URLs with fixed patches, prefer `fetchpatch2`.
- Start fixed-output patch hashes with `lib.fakeHash`, build once, then copy the
  `got:` SRI hash from the failure.

## Reporting Checklist

- Target built.
- Failing phase.
- Exact error excerpt.
- Relevant derivation fields, if inspected.
- Suspected cause.
- Minimal proposed change.
- Verification command.
