{
  description = "KhaneliNix";

  inputs = {
    # Astronvim repo
    astronvim = {
      url = "github:AstroNvim/AstroNvim/nightly";
      flake = false;
    };

    # Personal astronvim configuration
    astronvim-user = {
      url = "github:khaneliman/astronvim";
      flake = false;
    };

    # Comma
    comma.url = "github:nix-community/comma";
    comma.inputs.nixpkgs.follows = "nixpkgs";

    # macOS Support (master)
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    # System Deployment
    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    # Snowfall Flake
    flake.url = "github:snowfallorg/flake";
    flake.inputs.nixpkgs.follows = "nixpkgs";

    # GPG default configuration
    gpg-base-conf = {
      url = "github:drduh/config";
      flake = false;
    };

    # Home Manager (master)
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Hyprland
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";

    # Hyprland user contributions flake
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixPkgs (nixos-unstable)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # NixPkgs-Wayland 
    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";

    # Nix User Repository (master)
    nur.url = "github:nix-community/NUR";

    # Hardware Configuration
    nixos-hardware.url = "github:nixos/nixos-hardware";

    # Generate System Images
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";

    # NixOS WSL Support
    nixos-wsl.url = "github:nix-community/nixos-wsl";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    # Snowfall Lib
    snowfall-lib.url = "github:snowfallorg/lib";
    snowfall-lib.inputs.nixpkgs.follows = "nixpkgs";

    # Run unpatched dynamically compiled binaries
    nix-ld.url = "github:Mic92/nix-ld";
    nix-ld.inputs.nixpkgs.follows = "nixpkgs";

    # Ranger Dev Icons
    ranger-devicons.url = "github:alexanderjeurissen/ranger_devicons";
    ranger-devicons.flake = false;

    # Ranger Disk Menu
    ranger-udisk-menu.url = "github:SL-RU/ranger_udisk_menu";
    ranger-udisk-menu.flake = false;

    # Rust overlay
    rustup-overlay.url = "github:oxalica/rust-overlay";
    rustup-overlay.inputs.nixpkgs.follows = "nixpkgs";

    # SF Mono Nerd font 
    sf-mono-nerd-font.url = "github:shaunsingh/SFMono-Nerd-Font-Ligaturized";
    sf-mono-nerd-font.flake = false;

    # Sops (Secrets) 
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # Spicetify
    spicetify-nix.url = "github:the-argus/spicetify-nix/dev";
    spicetify-nix.inputs.nixpkgs.follows = "nixpkgs";

    # Yubikey Guide
    yubikey-guide = {
      url = "github:drduh/YubiKey-Guide";
      flake = false;
    };
  };

  outputs = inputs:
    let
      inherit (inputs) snowfall-lib flake hyprland nur rustup-overlay nix-ld sops-nix deploy-rs;

      lib = snowfall-lib.mkLib {
        inherit inputs;
        src = ./.;
      };
    in
    lib.mkFlake {
      package-namespace = "khanelinix";

      channels-config = {
        # allowBroken = true;
        allowUnfree = true;

        # TODO: cleanup when available
        permittedInsecurePackages = [
          "openssl-1.1.1v"
        ];
      };

      overlays = [
        flake.overlays.default
        hyprland.overlays.default
        # nixpkgs-wayland.overlay
        nur.overlay
        rustup-overlay.overlays.default
      ];

      systems = {
        modules = {
          darwin = [
          ];

          home = [
            sops-nix.homeManagerModules.sops
          ];

          nixos = [
            nix-ld.nixosModules.nix-ld
            sops-nix.nixosModules.sops
          ];
        };
      };

      deploy = lib.mkDeploy { inherit (inputs) self; };

      checks =
        builtins.mapAttrs
          (_system: deploy-lib:
            deploy-lib.deployChecks inputs.self.deploy)
          deploy-rs.lib;
    };
}

