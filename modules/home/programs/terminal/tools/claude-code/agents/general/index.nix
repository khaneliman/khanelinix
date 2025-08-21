{ lib, ... }:

lib.foldl' lib.recursiveUpdate { } [
  (import ./security-auditor.nix)
  (import ./code-reviewer.nix)
  (import ./documenter.nix)
]
