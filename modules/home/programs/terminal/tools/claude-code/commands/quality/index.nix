{ lib, ... }:

lib.foldl' lib.recursiveUpdate { } [
  (import ./quick-check.nix)
  (import ./deep-check.nix)
  (import ./style-audit.nix)
  (import ./dependency-audit.nix)
  (import ./module-lint.nix)
]
