{ lib, ... }:

lib.foldl' lib.recursiveUpdate { } [
  (import ./module-expert.nix)
  (import ./flake-expert.nix)
  (import ./nix-expert.nix)
]
