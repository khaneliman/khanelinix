{ inputs }:
{
  system,
  hostname ? null,
  username ? null,
  osConfig ? { },
}:
let
  inherit (inputs) self;
  bootstrapCommon = import ./common.nix { inherit inputs; };
  patchedInputs = bootstrapCommon.mkPatchedInputs { inherit system; };
  common = import ./common.nix { inputs = patchedInputs; };
in
{
  inherit
    system
    hostname
    username
    osConfig
    ;
}
// common.mkBoundArgs {
  inputs = patchedInputs;
  extendedLib = common.mkExtendedLib self (
    if inputs.nixpkgs.lib.hasSuffix "-darwin" system then
      patchedInputs.nixpkgs-unstable
    else
      patchedInputs.nixpkgs
  );
}
// common.mkInputPackageSets {
  inherit system;
  flake = self;
}
