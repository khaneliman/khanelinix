{ inputs }:
{
  system,
  hostname,
  username ? "khaneliman",
  modules ? [ ],
  ...
}:
let
  # Import the khaneliparts flake to access the overlay
  flake = inputs.self or (throw "mkSystem requires 'inputs.self' to be passed");

  # Extend nixpkgs lib with khanelinix functions
  extendedLib = inputs.nixpkgs.lib.extend flake.lib.overlay;

  # Auto-discover home configurations for this system+hostname
  inherit (flake.lib.file) scanHomes;
  homesPath = ../homes;
  allHomes = scanHomes homesPath;

  # Filter for matching system and hostname
  matchingHomes = extendedLib.filterAttrs (
    _name: homeConfig: homeConfig.system == system && homeConfig.hostname == hostname
  ) allHomes;

  # Generate home-manager configuration for matching users
  homeManagerConfig =
    if matchingHomes != { } then
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = {
            inherit inputs system;
            inherit (inputs) self;
            lib = extendedLib;
            flake-parts-lib = inputs.flake-parts.lib;
          };
          sharedModules = [
            # Provide extended lib to all modules
            { _module.args.lib = extendedLib; }

            inputs.home-manager.flakeModules.home-manager
            inputs.catppuccin.homeModules.catppuccin
            inputs.hypr-socket-watch.homeManagerModules.default
            inputs.nix-index-database.homeModules.nix-index
            inputs.sops-nix.homeManagerModules.sops
            ../modules/home
          ];
          users = extendedLib.mapAttrs' (_name: homeConfig: {
            name = homeConfig.username;
            value = {
              imports = [ homeConfig.path ];
              home = {
                inherit (homeConfig) username;
                homeDirectory = inputs.nixpkgs.lib.mkDefault "/home/${homeConfig.username}";
              };
              _module.args.username = homeConfig.username;
            };
          }) matchingHomes;
        };
      }
    else
      { };
in
inputs.nixpkgs.lib.nixosSystem {
  inherit system;

  specialArgs = {
    inherit inputs hostname username;
    inherit (inputs) self;
    lib = extendedLib;
    flake-parts-lib = inputs.flake-parts.lib;
    format = "system";
    host = hostname;
  };

  modules = [
    # Provide extended lib to all modules
    { _module.args.lib = extendedLib; }

    # Configure nixpkgs with overlays
    {
      nixpkgs = {
        inherit system;
        overlays = builtins.attrValues flake.overlays;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            # NOTE: citrix
            "libxml2-2.13.8"
          ];
        };
      };
    }

    # Home Manager NixOS module
    inputs.home-manager.nixosModules.home-manager

    # System modules
    inputs.lanzaboote.nixosModules.lanzaboote
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
    inputs.stylix.nixosModules.stylix
    inputs.catppuccin.nixosModules.catppuccin
    inputs.nix-index-database.nixosModules.nix-index
    inputs.nix-flatpak.nixosModules.nix-flatpak

    # Auto-inject home configurations for this system+hostname
    homeManagerConfig

    # Base system modules
    ../modules/nixos

    # Host-specific configuration
    ../systems/${system}/${hostname}

    # Additional modules passed as arguments
  ] ++ modules;
}
