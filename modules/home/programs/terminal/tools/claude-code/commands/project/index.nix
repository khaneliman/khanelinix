{ lib, ... }:

lib.foldl' lib.recursiveUpdate { } [
  (import ./changelog.nix)
]
