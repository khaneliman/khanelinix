{
  description = "KhaneliNix";

  inputs = {

    # Comma
    comma = {
      url = "github:nix-community/comma";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # macOS Support (master)
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # System Deployment
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Snowfall Flake
    flake = {
      url = "github:snowfallorg/flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # GPG default configuration
    gpg-base-conf = {
      url = "github:drduh/config";
      flake = false;
    };

    # Home Manager (master)
    home-manager = {
      url = "github:nix-community/home-manager";
      # url = "git+file:///home/khaneliman/Documents/github/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland user contributions flake
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secure boot 
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.3.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Personal neovim config
    astronvim-config = {
      url = "github:khaneliman/khanelivim/astronvim";
      flake = false;
    };

    lazyvim-config = {
      url = "github:khaneliman/khanelivim/lazyvim";
      flake = false;
    };

    lunarvim-config = {
      url = "github:LunarVim/LunarVim";
      flake = false;
    };

    neovim-config = {
      url = "github:khaneliman/khanelivim";
      flake = false;
    };

    # NixPkgs (nixos-unstable)
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    # NixPkgs (master)
    # nixpkgs-master = {
    #   url = "github:nixos/nixpkgs/master";
    # };
    #
    # Nixpkgs fork
    # nixpkgs-khanelinix = {
    #   url = "github:khaneliman/nixpkgs/yabai-update";
    # };

    # NixPkgs-Wayland 
    nixpkgs-wayland = {
      url = "github:nix-community/nixpkgs-wayland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix User Repository (master)
    nur = {
      url = "github:nix-community/NUR";
    };

    # Hardware Configuration
    nixos-hardware = {
      url = "github:nixos/nixos-hardware";
    };

    # Generate System Images
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS WSL Support
    nixos-wsl = {
      url = "github:nix-community/nixos-wsl";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Run unpatched dynamically compiled binaries
    nix-ld-rs = {
      url = "github:nix-community/nix-ld-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Ranger Dev Icons
    ranger-devicons = {
      url = "github:alexanderjeurissen/ranger_devicons";
      flake = false;
    };

    # Ranger Disk Menu
    ranger-udisk-menu = {
      url = "github:SL-RU/ranger_udisk_menu";
      flake = false;
    };

    # Rust overlay
    rustup-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Snowfall Lib
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    snowfall-frost = {
      url = "github:snowfallorg/frost";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Sops (Secrets) 
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Spicetify
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Yubikey Guide
    yubikey-guide = {
      url = "github:drduh/YubiKey-Guide";
      flake = false;
    };
  };

  outputs = inputs:
    let
      inherit (inputs) deploy-rs flake lanzaboote nur nix-ld-rs rustup-overlay snowfall-lib snowfall-frost sops-nix;

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
          "electron-25.9.0"
        ];
      };

      overlays = [
        flake.overlays.default
        # nixpkgs-wayland.overlay
        nix-ld-rs.overlays.default
        nur.overlay
        rustup-overlay.overlays.default
        snowfall-frost.overlays.default
      ];

      systems = {
        modules = {
          darwin = [
          ];

          ## TODO: update upstream to support
          # home = [
          #   sops-nix.homeManagerModules.sops
          # ];

          nixos = [
            lanzaboote.nixosModules.lanzaboote
            # nix-ld.nixosModules.nix-ld
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

