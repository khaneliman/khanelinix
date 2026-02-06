# Docs Pipeline

This site is built directly from the flake and the module option definitions.

## Pipeline steps

1. **Evaluate options** for NixOS, Darwin, and Home Manager via
   `nixosOptionsDoc` (filtered to `khanelinix.*`).
2. **Generate Markdown** from the options (`optionsCommonMark`).
3. **Split options** by top-level group with `docs/scripts/split-options.py`.
4. **Build mdBook** into a static HTML site.

## Commands

```bash
nix build .#docs-html
nix run .#docs
```

## Notes

- Home Manager options are evaluated with a **docs-only `osConfig` stub** so
  modules that expect system values can still render. Those values are
  placeholders for documentation purposes only.
- Raw generated options are copied into `raw-options/` in the built site.
