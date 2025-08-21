{ lib, ... }:

lib.foldl' lib.recursiveUpdate { } [
  (import ./add-and-format.nix)
  (import ./commit-smart.nix)
  (import ./review.nix)
  (import ./commit-msg.nix)
  (import ./commit-changes.nix)
]
