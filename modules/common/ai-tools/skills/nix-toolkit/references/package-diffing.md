# Package Diffing

## Protocol

1. Build local output and comparison output to separate result symlinks.
2. File-list diff first (cheap), then closure drift, then `diffoscope`.
3. Normalize store paths before reviewing textual diffs.
4. Report changed paths, metadata, closure drift, and impact.

## Local Change vs Base Revision

```bash
package="package-name"
base="HEAD^"

nix-build -A "$package" -o result-after
git worktree add --detach ../nixpkgs-base "$base"
nix-build ../nixpkgs-base -A "$package" -o result-before
nix store diff-closures result-before result-after
nix-shell -p diffoscope --run "diffoscope result-before result-after"
```

Remove the temporary worktree after investigation.

## Local vs Remote Branch

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

Use branch form for triage only; use fixed revision when result must be
reproducible.

## Fixed Revision Template

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

Add `sha256` to `fetchTarball` for durable docs/CI (one failed run prints the
expected hash).

## File List First Pass

```bash
find -L result-local -type f | sed 's#^result-local/##' | sort > local.files
find -L result-remote -type f | sed 's#^result-remote/##' | sort > remote.files
diff -u local.files remote.files
```

## Closure Comparison

```bash
nix path-info -Sh result-local
nix path-info -Sh result-remote
nix path-info -rSh result-local | sort > local.closure
nix path-info -rSh result-remote | sort > remote.closure
diff -u local.closure remote.closure
```

Scripted first pass:
`scripts/closure-diff-report.sh nixpkgs#hello nixpkgs#hello`

## Text Diff Normalization

```bash
diff -ru result-local result-remote \
  | sed -E 's#/nix/store/[a-z0-9]{32}-#/nix/store/<hash>-#g' \
  > normalized.diff
```

Hash-only changes usually indicate rebuild drift, not behavioral change.

## Diffoscope Tips

- Start with file lists; `diffoscope` can be slow on large outputs.
- Timestamps only → check `SOURCE_DATE_EPOCH` or strip nondeterministic archive
  metadata.
- ELF differences → compare `nix-store -q --references result-*` before assuming
  source changes.
- Fonts, icons, Python wheels, jars → inspect generated indexes and archive
  member ordering.

## Reporting Checklist

- Package, source revisions, system.
- Exact build commands or attributes.
- Outputs: byte-identical | file-list different | structurally different.
- Largest/riskiest changed paths.
- Closure size or dependency changes.
