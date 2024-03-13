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

    # Hypridle
    hypridle = {
      url = "github:hyprwm/Hypridle";
      # url = "git+file:///home/khaneliman/Documents/github/hypridle";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprlock = {
      url = "github:hyprwm/Hyprlock";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprpaper
    hyprpaper = {
      url = "github:hyprwm/hyprpaper";
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

    # Astronvim neovim config
    astronvim-config = {
      url = "github:khaneliman/khanelivim/astronvim";
      flake = false;
    };

    # lazyvim neovim config
    lazyvim-config = {
      url = "github:khaneliman/khanelivim/lazyvim";
      flake = false;
    };

    # lunarvim config
    lunarvim-config = {
      url = "github:LunarVim/LunarVim";
      flake = false;
    };

    # Personal neovim config
    neovim-config = {
      url = "github:khaneliman/khanelivim";
      flake = false;
    };

    # Neovim nightly overlay
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
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

    # Neovim nix configuration
    nixvim = {
      # url = "github:khaneliman/nixvim/telescope";
      url = "github:nix-community/nixvim";
      # url = "git+file:///Users/khaneliman/Documents/github/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix User Repository (master)
    nur = {
      url = "github:nix-community/NUR";
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
    rust-overlay = {
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
      inherit (inputs) deploy-rs flake hypridle lanzaboote neovim-nightly-overlay nix-ld-rs nixvim nur rust-overlay snowfall-lib snowfall-frost sops-nix;

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
          "freeimage-unstable-2021-11-01"
        ];
      };

      overlays = [
        flake.overlays.default
        hypridle.overlays.default
        # nixpkgs-wayland.overlay
        neovim-nightly-overlay.overlay
        nix-ld-rs.overlays.default
        nur.overlay
        rust-overlay.overlays.default
        snowfall-frost.overlays.default
      ];

      systems = {
        modules = {
          darwin = [
            nixvim.nixDarwinModules.nixvim
          ];

          ## TODO: update upstream to support
          # home = [
          #   sops-nix.homeManagerModules.sops
          # ];

          nixos = [
            lanzaboote.nixosModules.lanzaboote
            # nix-ld.nixosModules.nix-ld
            sops-nix.nixosModules.sops
            nixvim.nixosModules.nixvim
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

