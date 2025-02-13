{ lib, self, ... }:
let

  inherit (self.lib.khanelinix) getDefaultNixFilesRecursive;

  # Get all default.nix files in a directory and create importable modules
  wrapModules = dir: {
    imports = map (path: import (../. + "/${path}")) (getDefaultNixFilesRecursive dir);
  };

  # Module directories
  moduleDirectories = {
    common = ../modules/shared;
    darwin = ../modules/darwin;
    nixos = ../modules/nixos;
    home = ../modules/home;
  };
in
{
  flake = {
    darwinModules = {
      common = wrapModules moduleDirectories.common;
      darwin = wrapModules moduleDirectories.darwin;
    };

    nixosModules = {
      common = wrapModules moduleDirectories.common;
      nixos = wrapModules moduleDirectories.nixos;
    };

    homeModules = {
      common = wrapModules moduleDirectories.common;
      home = wrapModules moduleDirectories.home;
    };
  };
}
