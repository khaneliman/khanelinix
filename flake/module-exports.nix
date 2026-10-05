{ inputs, self, ... }:
let
  common = self.lib.system.common;
  integratedHome =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs =
          lib.removeAttrs
            (self.lib.system.moduleArgs {
              system = pkgs.stdenv.hostPlatform.system;
              hostname = config.networking.hostName;
            })
            [
              "osConfig"
              "username"
            ];
        sharedModules =
          common.hmSharedModules
          ++ [
            ({ name, ... }: { _module.args.username = name; })
          ]
          ++ lib.optionals (!(config.stylix.enable && config.stylix.homeManagerIntegration.autoImport)) [
            inputs.stylix.homeModules.stylix
            { stylix.overlays.enable = false; }
          ];
      };
    };

in
{
  flake = {
    nixosModules.default = {
      imports = [
        integratedHome
        ../modules/nixos
        inputs.home-manager.nixosModules.home-manager
        inputs.lanzaboote.nixosModules.lanzaboote
        inputs.sops-nix.nixosModules.sops
        inputs.disko.nixosModules.disko
        inputs.fast-nix-gc.nixosModules.default
        inputs.stylix.nixosModules.stylix
        inputs.catppuccin.nixosModules.catppuccin
        inputs.nix-index-database.nixosModules.nix-index
        inputs.nix-flatpak.nixosModules.nix-flatpak
      ];
      nixpkgs = common.mkNixpkgsConfig self;
    };
    darwinModules.default = {
      imports = [
        integratedHome
        ../modules/darwin
        inputs.home-manager.darwinModules.home-manager
        inputs.sops-nix.darwinModules.sops
        inputs.stylix.darwinModules.stylix
        inputs.nix-rosetta-builder.darwinModules.default
      ];
      nixpkgs = common.mkNixpkgsConfig self;
    };
    homeManagerModules.default = {
      imports = common.hmSharedModules ++ [ inputs.stylix.homeModules.stylix ];
      stylix.overlays.enable = false;
    };
    homeModules.default = self.homeManagerModules.default;
  };
}
