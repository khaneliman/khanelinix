# Package Diffing

## Pick the Tool

- `nix-diff` explains why two derivations differ (inputs, environment, build
  script) without building them.
- `nix store diff-closures` lists package and version changes between two
  closures; see [Closure analysis](closure-analysis.md).
- `nix store make-content-addressed` answers whether two outputs are identical
  apart from references to their own store paths.
- diffoscope shows what changed inside built files: ELF headers, symbols,
  strings, archives, and text.

## Deterministic First Pass

Compare any two Nix installables with the Python helper:

```bash
python3 "<path-to-skill>/scripts/package_diff_report.py" \
  --repo . \
  --before 'nixpkgs#hello' \
  --after '.#hello'
```

Helper builds with `--no-link`, `--no-update-lock-file`, and
`--no-write-lock-file`; it never creates checkout result links or modifies the
lock file. It hashes regular files, compares path metadata and recursive
closures, bounds large lists, and emits stable JSON. Use `--format text` for a
compact summary or `--no-file-hashes` for a cheaper metadata-only pass. A bare
installable builds only `outputsToInstall`; append `^*`, as in `'.#nano^*'`, to
compare every output. The helper pairs outputs in the order Nix prints them.

Add `--diffoscope` only after file and closure evidence warrants deeper work.
When diffoscope is not installed, run the helper inside
`nix shell nixpkgs#diffoscopeMinimal -c python3 ...`. Diffoscope writes its
temporary report outside checkout; helper returns a bounded excerpt with store
hashes normalized. Its `different` flag is true whenever bytes differ, including
a changed self-reference, so pair it with the content-addressed check below.
Missing diffoscope is a hard error instead of a silent skip.

For revision comparisons, pass immutable or explicitly selected installables.
Prefer fixed revisions over moving branches when result must be reproducible.

## Run Diffoscope

`diffoscopeMinimal` bundles binutils and `file`, which covers ELF binaries,
text, and common archives:

```bash
nix shell nixpkgs#diffoscopeMinimal -c diffoscope --text report.txt "$before" "$after"
```

Use the full `nixpkgs#diffoscope` only when `diffoscope --list-missing-tools`
names a comparator the outputs need, such as `pdftotext`, `javap`, `ffprobe`, or
`7z`.

- Exit status is 0 for identical inputs, 1 for differences, and 2 for errors. On
  exit 0 diffoscope writes no `--text` report file.
- The report is a tree. Each `├──` header names a file or the command that
  produced the section, such as `readelf --wide --notes {}` or
  `strings --all --bytes=8 {}`. Files without a specific comparator fall back to
  an `xxd` hexdump.
- For ELF changes, read the dynamic section (NEEDED, RUNPATH), symbol tables,
  and `strings` first. After a layout shift, disassembly hunks are mostly moved
  addresses.
- `--max-report-size` (40 MiB) and `--max-diff-block-lines` (1024) truncate
  large reports. `--html report.html` is easier to browse than text.

## Prove a Dependency Is Unused

The strongest evidence for removing a dependency is that every output stays
identical apart from self-references, which change because the output path hash
changes. A removal that changes output can still be correct, but it needs an
explanation. Before removing a dependency, find why it was added, for example
with `git log -S<name> -- <package-file>`. It may have replaced a vendored copy,
in which case the fix is to repair that substitution, not delete it.

1. Build every output of both variants from the same nixpkgs base. A reference
   can be a revision such as `github:NixOS/nixpkgs/<rev>` or a local checkout.
   To try a removal before editing nixpkgs, expose the package and an
   `overrideAttrs` variant using `lib.remove` from a scratch flake.

   ```bash
   nix build --no-link --print-out-paths "$base_ref#<attr>^*"
   nix build --no-link --print-out-paths "$change_ref#<attr>^*"
   ```

2. Factor out self-references with the experimental
   `nix store make-content-addressed`. It maps each input path to a
   content-addressed copy, rewriting self-references and dependency references
   alike. Outputs that map to the same path pass; any changed dependency
   reference fails. The copies of both closures stay in the store until garbage
   collection.

   ```bash
   nix store make-content-addressed --json "${before_outputs[@]}" "${after_outputs[@]}"
   ```

3. If an output differs, check that the baseline rebuilds reproducibly (see
   [Check Rebuild Reproducibility](#check-rebuild-reproducibility)). Differences
   between `<out>` and `<out>.check` come from nondeterminism and appear in
   every comparison of that package.

4. Explain what remains with diffoscope. Mask the two output hashes, not every
   store hash: a generic `/nix/store/[a-z0-9]{32}-` mask also hides a dependency
   that changed hash but kept its name. The mask clears self-references from
   text sections such as `strings`, but not from hexdumps where the hash spans
   rows, so a binary that embeds its own path still exits 1. The helper's
   closure section shows dropped runtime references.

   ```bash
   nix shell nixpkgs#diffoscopeMinimal -c diffoscope \
     --diff-mask "$before_hash|$after_hash" \
     --text report.txt "$before_out" "$after_out"
   ```

5. Sort each remaining difference:
   - Self-reference residue: with `separateDebugInfo`, the ELF build ID covers
     the embedded output path. The `-debug` output then differs throughout:
     build-ID file names, a `-frandom-seed` taken from the output hash, and
     compressed DWARF. Judge such packages by the main output.
   - Nondeterminism: the same differences appear between `<out>` and
     `<out>.check`.
   - Layout shift: dropping a library from RUNPATH, for example through
     `patchelf --shrink-rpath`, shrinks `.dynstr` and moves later sections, so
     most disassembly addresses change. Confirm NEEDED entries and symbols match
     and the dependency left the closure.
   - Real change: a NEEDED library or RUNPATH entry disappears, its undefined
     symbols go away, or `--version` and `--help` output changes. For example,
     nano built without `file` loses `libmagic.so.1`, the `magic_load` import,
     and its `--magic` option. Explain why the change is correct before keeping
     the removal.

## Check Rebuild Reproducibility

```bash
nix build --no-link --rebuild --keep-failed '.#pkg'
```

- The output must already be in the store, built locally or substituted from a
  binary cache. The rebuild always runs locally.
- A mismatch exits 1 with
  `derivation '<drv>' may not be deterministic: output "<out>" differs from "<out>.check"`.
  `--keep-failed` keeps the second build at `<out>.check`; without it, Nix
  reports the mismatch but keeps nothing to compare.
- Compare with
  `nix shell nixpkgs#diffoscopeMinimal -c diffoscope "$out" "$out.check"`.
- `<out>.check` is not a valid store path, so `nix path-info` rejects it; leave
  it for garbage collection. `--keep-failed` also keeps the root-owned build
  directory named in the `keeping build directory` note; remove it when done.
- The `diff-hook` and `run-diff-hook` settings run a program on every mismatch.
  The daemon reads them only from `nix.conf`, the hook runs as the build user,
  and its output goes to the daemon log, so the manual `.check` route is simpler
  for one-off checks.

## Interpretation

- Same file list with changed hashes: inspect content or generated metadata.
- Hash-only store-path drift: distinguish rebuild drift from behavior change.
- Timestamp-only archive drift: inspect `SOURCE_DATE_EPOCH` and archive member
  ordering.
- ELF differences: compare closure/reference changes before assuming source
  changes.
- Fonts, icons, wheels, and jars: inspect generated indexes and archive order.

## Reporting Checklist

- Compared installables, source revisions, and system.
- Comparison method and whether file hashing or diffoscope ran.
- Byte-identical, file-list different, or structurally different outputs.
- For dependency removals, the content-addressed result per output and the
  category of each remaining difference.
- Whether the baseline rebuilds reproducibly, when outputs differ.
- Largest or riskiest changed paths.
- Closure size and dependency changes.
