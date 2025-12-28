{ inputs }:
/**
  Create a NixOS system configuration.

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
  flake = inputs.self or (throw "mkSystem requires 'inputs.self' to be passed");
  common = import ./common.nix { inherit inputs; };

  extendedLib = common.mkExtendedLib flake inputs.nixpkgs;
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
    isNixOS = true;
  };
in
inputs.nixpkgs.lib.nixosSystem {
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

    inputs.home-manager.nixosModules.home-manager
    inputs.lanzaboote.nixosModules.lanzaboote
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
    inputs.stylix.nixosModules.stylix
    inputs.catppuccin.nixosModules.catppuccin
    inputs.nix-index-database.nixosModules.nix-index
    inputs.nix-flatpak.nixosModules.nix-flatpak

    # Auto-inject home configurations for this system+hostname
    homeManagerConfig

    # Import all nixos modules recursively
  ]
  ++ (extendedLib.importModulesRecursive ../../modules/nixos)
  ++ [
    ../../systems/${system}/${hostname}
  ]
  ++ modules;
}
