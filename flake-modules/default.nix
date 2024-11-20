{ inputs, ... }:
{
  imports = [
    ./dev
    ./lib.nix
    ./overlays.nix
    ./packages.nix
    ./templates.nix
  ];

  perSystem =
    { system, ... }:
    {
      _module.args = {
        pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      };
    };
}
