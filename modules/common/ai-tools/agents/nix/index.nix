{ lib, ... }:

lib.foldl' lib.recursiveUpdate { } [
  (import ./nix-module-coder.nix)
  (import ./flake-coder.nix)
  (import ./nix-coder.nix)
]
