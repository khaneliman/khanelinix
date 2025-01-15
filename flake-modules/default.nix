{
  inputs,
  lib,
  self,
  ...
}:
{
  imports = [
    ./checks.nix
    ./devshell.nix
    ./git-hooks.nix
    ./lib.nix
    ./overlays.nix
    ./pkgs-by-name.nix
    ./treefmt.nix
  ];

  perSystem =
    {
      self',
      system,
      ...
    }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = lib.attrValues self.overlays;
        config.allowUnfree = true;
      };

      packages.default = self'.packages.khanelivim;
    };
}
