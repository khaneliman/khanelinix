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
    ./templates.nix
    ./treefmt.nix
  ];

  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = lib.mkDefault (
        import inputs.nixpkgs {
          inherit system;
          overlays = allOverlays;
          config = { };
        }
      );
    };
}
