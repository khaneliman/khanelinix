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
      ]
      ++ common.nixosUpstreamModules inputs;
      nixpkgs = common.mkNixpkgsConfig self;
    };
    darwinModules.default = {
      imports = [
        integratedHome
        ../modules/darwin
      ]
      ++ common.darwinUpstreamModules inputs;
      nixpkgs = common.mkNixpkgsConfig self;
    };
    homeManagerModules.default = {
      imports = common.hmSharedModules ++ [ inputs.stylix.homeModules.stylix ];
      stylix.overlays.enable = false;
    };
    homeModules.default = self.homeManagerModules.default;
  };
}
