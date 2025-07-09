{ lib, ... }:
let
  importList = lib.khanelinix.getDefaultNixFilesRecursive ./.;
in
{
  imports = builtins.trace "TRACE: modules/nixos/default.nix importing: ${toString importList}" importList;
}
