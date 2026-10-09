{ inputs, self, ... }:
let
  inherit (inputs.nixpkgs) lib;
  common = self.lib.system.common;

  bind =
    nixpkgs:
    common.bindModules (
      common.mkBoundArgs {
        inherit inputs;
        extendedLib = common.mkExtendedLib self nixpkgs;
      }
    );

  # Keys let a consumer reach an aggregate through more than one import
  # without declaring its options twice.
  exportKey = name: "${toString ../.}#${name}";

  packageSetArgs =
    pkgs:
    common.mkInputPackageSets {
      flake = self;
      system = pkgs.stdenv.hostPlatform.system;
    };

  # The fleet passes these per-host arguments through specialArgs. These
  # defaults derive them from configuration instead, so consumers need no
  # specialArgs and their own definitions still win.
  systemArgs =
    { config, pkgs, ... }:
    {
      _module.args = lib.mapAttrs (_: lib.mkDefault) (
        {
          system = pkgs.stdenv.hostPlatform.system;
          hostname = config.networking.hostName;
          username = config.khanelinix.user.name;
        }
        // packageSetArgs pkgs
      );
    };

  homeArgs =
    {
      config,
      osConfig,
      pkgs,
      ...
    }:
    {
      _module.args = lib.mapAttrs (_: lib.mkDefault) (
        {
          system = pkgs.stdenv.hostPlatform.system;
          hostname = osConfig.networking.hostName or null;
          username = config.home.username;
        }
        // packageSetArgs pkgs
      );
    };

  homeAggregate = {
    key = exportKey "home";
    imports = bind inputs.nixpkgs common.hmSharedModules ++ [ homeArgs ];
  };

  stylixHome = {
    key = exportKey "stylix-home";
    imports = [
      inputs.stylix.homeModules.stylix
      { stylix.overlays.enable = false; }
    ];
  };

  integratedHome =
    { config, ... }:
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        sharedModules = [
          homeAggregate
        ]
        ++ lib.optional (
          !(config.stylix.enable && config.stylix.homeManagerIntegration.autoImport)
        ) stylixHome;
      };
    };

in
{
  flake = {
    nixosModules.default = {
      key = exportKey "nixosModules.default";
      imports = [
        integratedHome
        systemArgs
      ]
      ++ common.nixosUpstreamModules inputs
      ++ bind inputs.nixpkgs [ ../modules/nixos ];
      nixpkgs = common.mkNixpkgsConfig self;
      # The fleet sets networking.hostName from its hostname argument; a
      # consumer sets networking.hostName directly.
      khanelinix.system.hostname.enable = lib.mkDefault false;
    };
    darwinModules.default = {
      key = exportKey "darwinModules.default";
      imports = [
        integratedHome
        systemArgs
      ]
      ++ common.darwinUpstreamModules inputs
      ++ bind inputs.nixpkgs-unstable [ ../modules/darwin ];
      nixpkgs = common.mkNixpkgsConfig self;
    };
    homeManagerModules.default = {
      key = exportKey "homeManagerModules.default";
      imports = [
        homeAggregate
        stylixHome
      ];
    };
    homeModules.default = self.homeManagerModules.default;
  };
}
