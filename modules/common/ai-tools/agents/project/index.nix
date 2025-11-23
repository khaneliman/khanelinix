{ lib, ... }:

lib.foldl' lib.recursiveUpdate { } [
  (import ./dotfiles-coder.nix)
  (import ./template-writer.nix)
  (import ./system-planner.nix)
]
