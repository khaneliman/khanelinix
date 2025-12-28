{ inputs }:
/**
  Create a Home Manager configuration.

  # Inputs

  `system`

  : System architecture

  `hostname`

  : Host name

  `username`

  : User name

  `modules`

  : List of additional modules
*/
{
  system,
  hostname,
  username ? "khaneliman",
  modules ? [ ],
  ...
}:
let
  flake = inputs.self or (throw "mkHome requires 'inputs.self' to be passed");
  common = import ./common.nix { inherit inputs; };

  extendedLib = common.mkExtendedLib flake inputs.nixpkgs-unstable;
in
inputs.home-manager.lib.homeManagerConfiguration {
  pkgs = import inputs.nixpkgs-unstable {
    inherit system;
    inherit ((common.mkNixpkgsConfig flake)) config overlays;
  };

  extraSpecialArgs = {
    inherit
      inputs
      hostname
      username
      system
      ;
    inherit (flake) self;
    lib = extendedLib;
    flake-parts-lib = inputs.flake-parts.lib;
  };

  modules = [
    { _module.args.lib = extendedLib; }

    inputs.catppuccin.homeModules.catppuccin
    inputs.hypr-socket-watch.homeManagerModules.default
    inputs.nix-index-database.homeModules.nix-index
    inputs.sops-nix.homeManagerModules.sops

    # Import all home modules recursively
  ]
  ++ (extendedLib.importModulesRecursive ../../modules/home)
  ++ modules;
}
