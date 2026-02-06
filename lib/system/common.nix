{ inputs }:
let
  inherit (inputs.nixpkgs.lib) filterAttrs mapAttrs';

  /**
    Shared Home Manager modules used by both standalone (mkHome) and integrated
    (mkHomeManagerConfig) paths. Single source of truth to prevent drift.
  */
  hmSharedModules =
    extendedLib:
    [
      inputs.catppuccin.homeModules.catppuccin
      inputs.hypr-socket-watch.homeManagerModules.default
      inputs.nix-index-database.homeModules.nix-index
      inputs.sops-nix.homeManagerModules.sops
    ]
    ++ (extendedLib.importModulesRecursive ../../modules/home);
in
{
  inherit hmSharedModules;
  /**
    Create an extended library with the flake's overlay.

    # Inputs

    `flake`

    : 1\. Function argument

    `nixpkgs`

    : 2\. Function argument
  */
  mkExtendedLib = flake: nixpkgs: nixpkgs.lib.extend flake.lib.overlay;

  /**
    Create a nixpkgs configuration with overlays and unfree packages enabled.

    # Inputs

    `flake`

    : 1\. Function argument
  */
  mkNixpkgsConfig = flake: {
    overlays = builtins.attrValues flake.overlays;
    config = {
      allowAliases = false;
      allowUnfree = true;
      permittedInsecurePackages = [
        # NOTE: citrix
        "libxml2-2.13.8"
        "libsoup-2.74.3"
        # NOTE: needed by emulationstation
        "freeimage-3.18.0-unstable-2024-04-18"
        "mbedtls-2.28.10"
        # dev shells
        "aspnetcore-runtime-6.0.36"
        "aspnetcore-runtime-7.0.20"
        "aspnetcore-runtime-wrapped-7.0.20"
        "aspnetcore-runtime-wrapped-6.0.36"
        "dotnet-combined"
      ];
    };
  };

  /**
    Get home configurations matching a specific system and hostname.

    # Inputs

    `flake`

    : Flake instance

    `system`

    : System architecture

    `hostname`

    : Host name
  */
  mkHomeConfigs =
    {
      flake,
      system,
      hostname,
    }:
    let
      inherit (flake.lib.file) parseHomeConfigurations;
      homesPath = ../../homes;
      allHomes = parseHomeConfigurations homesPath;
    in
    filterAttrs (
      _name: homeConfig: homeConfig.system == system && homeConfig.hostname == hostname
    ) allHomes;

  /**
    Create a Home Manager configuration for a system.

    # Inputs

    `extendedLib`

    : Extended library

    `inputs`

    : Flake inputs

    `system`

    : System architecture

    `matchingHomes`

    : Matching home configurations

    `isNixOS`

    : Whether the system is NixOS
  */
  mkHomeManagerConfig =
    {
      extendedLib,
      inputs,
      system,
      hostname,
      matchingHomes,
      isNixOS ? true,
    }:
    if matchingHomes != { } then
      { config, ... }:
      let
        stylixHomeModule =
          if inputs.stylix ? homeModules && inputs.stylix.homeModules ? stylix then
            inputs.stylix.homeModules.stylix
          else
            null;
        enableStylixHomeModule = stylixHomeModule != null && !(config.stylix.enable or false);
      in
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = {
            inherit inputs system hostname;
            inherit (inputs) self;
            lib = extendedLib;
            flake-parts-lib = inputs.flake-parts.lib;
          };
          sharedModules =
            hmSharedModules extendedLib
            ++ extendedLib.optional enableStylixHomeModule stylixHomeModule
            # NOTE: https://github.com/nix-community/stylix/issues/1832
            ++ extendedLib.optional enableStylixHomeModule {
              stylix.overlays.enable = false;
            };
          users = mapAttrs' (_name: homeConfig: {
            name = homeConfig.username;
            value = {
              imports = [ homeConfig.path ];
              home = {
                inherit (homeConfig) username;
                homeDirectory = inputs.nixpkgs.lib.mkDefault (
                  if isNixOS then "/home/${homeConfig.username}" else "/Users/${homeConfig.username}"
                );
              };
            }
            // (
              if isNixOS then
                {
                  _module.args.username = homeConfig.username;
                }
              else
                { }
            );
          }) matchingHomes;
        };
      }
    else
      { };

  /**
    Create special arguments for system configurations.

    # Inputs

    `inputs`

    : Flake inputs

    `hostname`

    : Host name

    `username`

    : User name

    `extendedLib`

    : Extended library
  */
  mkSpecialArgs =
    {
      inputs,
      hostname,
      username,
      extendedLib,
    }:
    {
      inherit inputs hostname username;
      inherit (inputs) self;
      lib = extendedLib;
      flake-parts-lib = inputs.flake-parts.lib;
      format = "system";
    };
}
