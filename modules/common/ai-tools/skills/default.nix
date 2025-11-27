{ lib }:

lib.foldl' lib.recursiveUpdate { } [
  # khanelinix-specific skills
  (import ./khanelinix/module-layout.nix)
  (import ./khanelinix/options-design.nix)
  (import ./khanelinix/config-layering.nix)
  (import ./khanelinix/theming.nix)

  # Nix language skills
  (import ./nix/lib-usage.nix)
  (import ./nix/conditionals.nix)
  (import ./nix/module-template.nix)
  (import ./nix/option-types.nix)
  (import ./nix/naming.nix)

  # Validation skills (per-language)
  (import ./validation/nix.nix)
  (import ./validation/typescript.nix)
  (import ./validation/python.nix)
  (import ./validation/rust.nix)
  (import ./validation/dotnet.nix)
]
