{ lib, ... }:

lib.foldl' lib.recursiveUpdate { } [
  (import ./refactor.nix)
  (import ./flake-update.nix)
  (import ./module-scaffold.nix)
  (import ./option-migrate.nix)
  (import ./template-new.nix)
  (import ./nix-check.nix)
]
