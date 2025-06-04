{ lib, ... }:
{
  imports = lib.khanelinix.getDefaultNixFilesRecursive ./.;
}