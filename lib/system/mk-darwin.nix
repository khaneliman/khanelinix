{ inputs }:
/**
  Create a Darwin system configuration.

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
  flake = inputs.self or (throw "mkDarwin requires 'inputs.self' to be passed");
  common = import ./common.nix { inherit inputs; };

  extendedLib = common.mkExtendedLib flake inputs.nixpkgs-unstable;
  matchingHomes = common.mkHomeConfigs {
    inherit
      flake
      system
      hostname
      ;
  };
  homeManagerConfig = common.mkHomeManagerConfig {
    inherit
      extendedLib
      inputs
      system
      matchingHomes
      ;
    isNixOS = false;
  };
in
inputs.nix-darwin.lib.darwinSystem {
  inherit system;

  specialArgs = common.mkSpecialArgs {
    inherit
      inputs
      hostname
      username
      extendedLib
      ;
  };

  modules = [
    { _module.args.lib = extendedLib; }

    # Configure nixpkgs with overlays
    {
      nixpkgs = {
        inherit system;
      }
      // common.mkNixpkgsConfig flake;
    }

    inputs.home-manager.darwinModules.home-manager
    inputs.sops-nix.darwinModules.sops
    inputs.stylix.darwinModules.stylix
    inputs.nix-rosetta-builder.darwinModules.default

    # Auto-inject home configurations for this system+hostname
    homeManagerConfig

    # Import all darwin modules recursively
  ]
  ++ (extendedLib.importModulesRecursive ../../modules/darwin)
  ++ [
    ../../systems/${system}/${hostname}
  ]
  ++ modules;
}
