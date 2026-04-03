# Module Boundaries

Split modules by responsibility, not by aesthetic neatness.

## Decision Rule

1. Keep a module single-file when it expresses one cohesive concern and is still
   easy to scan.
2. Split a module into a directory when it grows into multiple distinct
   concerns, multiple option groups, or separate integration points.
3. Do not create submodules just to make files shorter or to hide a simple
   implementation behind structure.
4. When splitting, keep the top-level file responsible for the public option
   surface and high-level composition.

## Preferences

- One module should usually own one responsibility.
- Keep option definitions close to the module that owns them.
- Keep private helpers or subordinate config in nearby files, not in unrelated
  generic utility modules.
- Do not split a tiny module into `default.nix`, `options.nix`, and `config.nix`
  unless that separation is genuinely buying clarity.

## Good Shape

- `default.nix`: compose the module and expose the public surface.
- `options.nix`: only when the option surface is large enough to justify
  separation.
- `theme.nix`, `services.nix`, `packages.nix`, etc.: use targeted filenames that
  match real sub-concerns.

If you cannot name the split clearly, the split is probably premature.
