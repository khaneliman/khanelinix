# Package Diffing

Use this playbook to compare package outputs across local changes, branches,
forks, or nixpkgs revisions.

## Default Workflow

1. Build the local package output.
2. Build the comparison package output to a separate result symlink.
3. Compare file lists and closure drift before deep byte-level inspection.
4. Normalize store paths before reviewing textual diffs.
5. Run `diffoscope` for structured output differences.
6. Report changed paths, changed metadata, closure drift, and likely impact.

## Local Change vs Base Revision

Use this when the current checkout changed a package and Git can provide the
base tree:

```bash
package="package-name"
base="HEAD^"

nix-build -A "$package" -o result-after
git worktree add --detach ../nixpkgs-base "$base"
nix-build ../nixpkgs-base -A "$package" -o result-before
nix store diff-closures result-before result-after
nix-shell -p diffoscope --run "diffoscope result-before result-after"
```

Remove the temporary worktree after investigation. Do not use this if the repo
already has a user-managed worktree at the target path.

## Local vs Remote Branch

Use this shape when comparing the local checkout against a GitHub fork branch:

```bash
remote="owner:branch"
package="package-name"

nix-build -A "$package" -o result-local \
  && nix-build -E '
    { remote, package }:
    let
      parts = builtins.split ":" remote;
      owner = builtins.elemAt parts 0;
      branch = builtins.elemAt parts 2;

      pkgs = import (fetchTarball {
        url = "https://github.com/${owner}/nixpkgs/archive/${branch}.tar.gz";
      }) {};
    in pkgs.${package}
  ' --argstr remote "$remote" --argstr package "$package" -o result-remote \
  && nix-shell -p diffoscope --run "diffoscope result-local result-remote"
```

Use a fixed nixpkgs revision or hash-pinned fetch when the result must be
reproducible. Use the branch form for quick review triage only.

## Fixed Revision Template

Prefer this shape when the comparison must be repeatable:

```bash
package="package-name"
owner="NixOS"
rev="nixos-unstable"

nix-build -A "$package" -o result-local
nix-build -E '
  { owner, rev, package }:
  let
    pkgs = import (fetchTarball {
      url = "https://github.com/${owner}/nixpkgs/archive/${rev}.tar.gz";
    }) {};
  in pkgs.${package}
' --argstr owner "$owner" --argstr rev "$rev" --argstr package "$package" -o result-remote
```

For durable docs or CI, add `sha256` to `fetchTarball` after one failed run
prints the expected hash.

## File List First Pass

```bash
find -L result-local -type f | sed 's#^result-local/##' | sort > local.files
find -L result-remote -type f | sed 's#^result-remote/##' | sort > remote.files
diff -u local.files remote.files
```

This catches added, removed, or relocated files before expensive deep diffs.

## Closure Comparison

```bash
nix path-info -Sh result-local
nix path-info -Sh result-remote
nix path-info -rSh result-local | sort > local.closure
nix path-info -rSh result-remote | sort > remote.closure
diff -u local.closure remote.closure
```

Use closure diffs when output files match but dependencies or size may have
changed.

For a scripted first pass against two installables or store paths, use:

```bash
scripts/closure-diff-report.sh nixpkgs#hello nixpkgs#hello
```

## Text Diff Normalization

Use this before drawing conclusions from generated text that embeds store paths:

```bash
diff -ru result-local result-remote \
  | sed -E 's#/nix/store/[a-z0-9]{32}-#/nix/store/<hash>-#g' \
  > normalized.diff
```

Hash-only changes often indicate rebuild drift, not behavioral change. Path
names, versions, embedded absolute paths, and generated metadata still matter.

## Diffoscope Triage Tips

- Start with file lists when the output is large; `diffoscope` can be slow.
- If only timestamps differ, check whether the package should set
  `SOURCE_DATE_EPOCH` or strip nondeterministic archive metadata.
- If ELF differences appear, compare references with
  `nix-store -q
  --references result-*` before assuming source changes.
- For fonts, icons, Python wheels, and jars, inspect generated indexes and
  archive member ordering; these often explain large binary-looking diffs.

## Reporting Checklist

- Compared package, source revisions, and system.
- Exact build commands or attributes.
- Whether outputs are byte-identical, file-list different, or structurally
  different.
- Largest or riskiest changed paths.
- Whether closure size or dependencies changed.
