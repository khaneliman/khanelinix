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
  osConfig ? { },
  sharedHomeModules ? null,
  pkgs ? null,
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
      "sops-nix"
    ];
  };
  common = import ./common.nix { inputs = patchedInputs; };
  flake = patchedInputs.self or (throw "mkHome requires 'inputs.self' to be passed");

  # Match the nixpkgs base of the platform system builder so standalone and
  # embedded Home Manager evaluate the same revision.
  nixpkgsInput =
    if inputs.nixpkgs.lib.hasSuffix "-linux" system then
      patchedInputs.nixpkgs
    else
      patchedInputs.nixpkgs-unstable;
  extendedLib = common.mkExtendedLib flake nixpkgsInput;
  inputPackageSets = common.mkInputPackageSets {
    inherit flake system;
  };
  homePkgs =
    if pkgs != null then
      pkgs
    else
      import nixpkgsInput {
        inherit system;
        inherit ((common.mkNixpkgsConfig flake)) config overlays;
      };

in
patchedInputs.home-manager.lib.homeManagerConfiguration {
  pkgs = homePkgs;

  extraSpecialArgs = {
    inherit
      hostname
      username
      system
      ;
    inherit osConfig;
    pkgs = homePkgs;
    inputs = patchedInputs;
    inherit (patchedInputs) self;
    lib = extendedLib;
    flake-parts-lib = patchedInputs.flake-parts.lib;
  }
  // inputPackageSets;

  modules =
    (
      if sharedHomeModules != null then
        sharedHomeModules
      else
        common.hmSharedModules ++ [ patchedInputs.stylix.homeModules.stylix ]
    )
    ++ [ { stylix.overlays.enable = false; } ]
    ++ modules;
}
