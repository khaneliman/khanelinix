{
  inputs,
  lib,
  self,
  ...
}:
{
  imports = [
    ./configs.nix
    ./devshell.nix
    ./git-hooks.nix
    ./lib.nix
    ./overlays.nix
    ./packages.nix
    ./treefmt.nix
  ];

  perSystem =
    {
      system,
      ...
    }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = lib.attrValues self.overlays;
        config.allowUnfree = true;
      };

      _module.args.root = ../.;
    };
}
