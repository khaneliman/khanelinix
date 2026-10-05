{ inputs }:
let
  inherit (inputs) self;
  common = import ./common.nix { inherit inputs; };
in
{
  system,
  hostname ? null,
  username ? null,
  osConfig ? { },
}:
{
  inherit
    system
    hostname
    username
    osConfig
    inputs
    self
    ;
  lib = common.mkExtendedLib self (
    if inputs.nixpkgs.lib.hasSuffix "-darwin" system then inputs.nixpkgs-unstable else inputs.nixpkgs
  );
  flake-parts-lib = inputs.flake-parts.lib;
  format = "system";
}
// common.mkInputPackageSets {
  inherit system;
  flake = self;
}
