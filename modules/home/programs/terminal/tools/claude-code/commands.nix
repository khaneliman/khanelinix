{ lib, ... }:

lib.foldl' lib.recursiveUpdate { } [
  (import ./commands/nix/index.nix { inherit lib; })
  (import ./commands/git/index.nix { inherit lib; })
  (import ./commands/quality/index.nix { inherit lib; })
  (import ./commands/project/index.nix { inherit lib; })
]
