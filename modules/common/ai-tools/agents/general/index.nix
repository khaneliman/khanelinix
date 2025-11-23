{ lib, ... }:

lib.foldl' lib.recursiveUpdate { } [
  (import ./security-auditor.nix)
  (import ./code-reviewer.nix)
  (import ./docs-writer.nix)
]
