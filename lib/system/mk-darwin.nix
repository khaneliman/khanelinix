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
  matchingHomes ? null,
  darwinModules ? null,
  sharedHomeModules ? null,
  extraInputPatches ? { },
  modules ? [ ],
  ...
}:
let
  bootstrapCommon = import ./common.nix { inherit inputs; };
  patchedInputs = bootstrapCommon.mkPatchedInputs {
    inherit system extraInputPatches;
  };
  common = import ./common.nix { inputs = patchedInputs; };
  flake = patchedInputs.self or (throw "mkDarwin requires 'inputs.self' to be passed");

  extendedLib = common.mkExtendedLib flake patchedInputs.nixpkgs-unstable;
  baseDarwinModules =
    if darwinModules == null then
      (extendedLib.importModulesRecursive ../../modules/darwin)
    else
      darwinModules;
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
    isNixOS = false;
  };
in
patchedInputs.nix-darwin.lib.darwinSystem {
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

    patchedInputs.home-manager.darwinModules.home-manager
    patchedInputs.sops-nix.darwinModules.sops
    patchedInputs.stylix.darwinModules.stylix
    patchedInputs.nix-rosetta-builder.darwinModules.default

    # Auto-inject home configurations for this system+hostname
    homeManagerConfig

    # Import all darwin modules recursively
  ]
  ++ baseDarwinModules
  ++ [
    ../../systems/${system}/${hostname}
  ]
  ++ modules;
}
