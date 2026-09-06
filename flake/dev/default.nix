{
  inputs,
  lib,
  ...
}:
let
  overlaysConfig = import ../overlays.nix { inherit inputs lib; };
  allOverlays = lib.attrValues overlaysConfig.flake.overlays;
in
{
  imports = [
    ./devshells.nix
    ./checks.nix
    ./parse.nix
    ./templates.nix
    ./tests.nix
    ./treefmt.nix
  ];

  perSystem =
    { system, ... }:
    {
      # Dev tooling needs nixpkgs aliases that the host policy disables.
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = allOverlays;
        config = { };
      };
    };
}
