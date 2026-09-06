{ inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;
in
{
  imports = [
    ../lib
    ./overlays.nix
    ./packages.nix
    ./configs.nix
    ./home.nix
    ./apps.nix
    ./docs.nix
    ./tests.nix
    inputs.flake-parts.flakeModules.partitions
  ];

  perSystem =
    { system, ... }:
    {
      # Flake outputs share the host nixpkgs policy so unfree local packages
      # evaluate under `nix flake check`.
      _module.args.pkgs = lib.mkDefault (
        import inputs.nixpkgs (
          inputs.self.lib.system.common.mkNixpkgsConfig inputs.self // { inherit system; }
        )
      );
    };

  partitions.dev = {
    module = ./dev;
    extraInputsFlake = ./dev;
  };

  partitionedAttrs = lib.genAttrs [
    "checks"
    "devShells"
    "formatter"
    "templates"
  ] (_: "dev");
}
