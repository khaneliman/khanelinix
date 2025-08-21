{ lib, ... }:

lib.foldl' lib.recursiveUpdate { } [
  (import ./refactor.nix)
  (import ./module-expert.nix)
  (import ./flake-expert.nix)
  (import ./nix-expert.nix)
]
