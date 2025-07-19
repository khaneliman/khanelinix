{ inputs, ... }:
{
  imports = [
    ../lib
    ./overlays.nix
    ./packages.nix
    ./configs.nix
    ./home.nix
    ./templates.nix
    inputs.flake-parts.flakeModules.partitions
  ];

  partitions.dev = {
    module = ./dev;
    extraInputsFlake = ./dev;
  };

  partitionedAttrs = inputs.nixpkgs.lib.genAttrs [
    "checks"
    "devShells"
    "formatter"
  ] (_: "dev");
}
