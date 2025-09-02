{ lib, ... }:

lib.foldl' lib.recursiveUpdate { } [
  (import ./add-and-format.nix)
  (import ./review.nix)
  (import ./commit-msg.nix)
  (import ./commit-changes.nix)
]
