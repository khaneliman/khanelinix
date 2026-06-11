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
  matchingHomes ? null,
  nixosModules ? null,
  sharedHomeModules ? null,
  extraInputPatches ? { },
  modules ? [ ],
  ...
}:
let
  bootstrapCommon = import ./common.nix { inherit inputs; };
  patchedInputs = bootstrapCommon.mkPatchedInputs {
    inherit system extraInputPatches;
    patchableInputs = [
      "nixpkgs"
      "nixpkgs-unstable"
      "nixpkgs-master"
      "home-manager"
    ];
  };
  common = import ./common.nix { inputs = patchedInputs; };
  flake = patchedInputs.self or (throw "mkSystem requires 'inputs.self' to be passed");

  extendedLib = common.mkExtendedLib flake patchedInputs.nixpkgs;
  baseSystemModules =
    if nixosModules == null then
      (extendedLib.importModulesRecursive ../../modules/nixos)
    else
      nixosModules;
  inputPackageSets = common.mkInputPackageSets {
    inherit flake system;
  };
  resolvedMatchingHomes =
    if matchingHomes == null then
      common.mkHomeConfigs {
        inherit
          flake
          system
          hostname
          ;
      }
    else
      matchingHomes;
  homeManagerConfig = common.mkHomeManagerConfig {
    inherit
      extendedLib
      system
      hostname
      inputPackageSets
      sharedHomeModules
      ;
    inputs = patchedInputs;
    matchingHomes = resolvedMatchingHomes;
    isNixOS = true;
  };
in
patchedInputs.nixpkgs.lib.nixosSystem {
  inherit system;

  specialArgs = common.mkSpecialArgs {
    inherit
      hostname
      username
      extendedLib
      inputPackageSets
      ;
    inputs = patchedInputs;
  };

  modules = [
    # Configure nixpkgs with overlays
    {
      nixpkgs = {
        inherit system;
      }
      // common.mkNixpkgsConfig flake;
    }

    patchedInputs.home-manager.nixosModules.home-manager
    patchedInputs.lanzaboote.nixosModules.lanzaboote
    patchedInputs.sops-nix.nixosModules.sops
    patchedInputs.disko.nixosModules.disko
    patchedInputs.fast-nix-gc.nixosModules.default
    patchedInputs.stylix.nixosModules.stylix
    patchedInputs.catppuccin.nixosModules.catppuccin
    patchedInputs.nix-index-database.nixosModules.nix-index
    patchedInputs.nix-flatpak.nixosModules.nix-flatpak

    # Auto-inject home configurations for this system+hostname
    homeManagerConfig

    # Import all nixos modules recursively
  ]
  ++ baseSystemModules
  ++ [
    ../../systems/${system}/${hostname}
  ]
  ++ modules;
}
