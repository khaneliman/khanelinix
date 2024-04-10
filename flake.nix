{
  description = "KhaneliNix";

  inputs = {

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

    # Hyprcursor
    hyprcursor = {
      url = "github:hyprwm/Hyprcursor";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        hyprlang.follows = "hyprlang";
      };
    };

    # Hyprcatosvg
    hyprcatosvg = {
      url = "github:entailz/HyprcatoSVG";
      flake = false;
    };

    # Hyprcursor-catppuccin
    hyprcursor-catppuccin = {
      url = "github:NotAShelf/hyprcursor-catppuccin";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    # Hypridle
    hypridle = {
      url = "github:hyprwm/Hypridle";
      inputs.nixpkgs.follows = "nixpkgs";
      # url = "git+file:///home/khaneliman/Documents/github/hypridle";
    };

    # Hyprlock
    hyprlock = {
      url = "github:hyprwm/Hyprlock";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        hyprlang.follows = "hyprlang";
        hyprcursor.follows = "hyprcursor";
      };
    };

    hyprlang = {
      url = "github:hyprwm/hyprlang";
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

    # Hyprland plugins
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    # Hyprland plugins
    hypr-socket-watch = {
      url = "github:khaneliman/hypr-socket-watch";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        hyprland.follows = "hyprland";
      };
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

    # NixPkgs (nixos-unstable)
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

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
      url = "github:nix-community/nixvim";
      # url = "git+file:///Users/khaneliman/Documents/github/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix User Repository (master)
    nur = {
      url = "github:nix-community/NUR";
    };

    # Rust overlay
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Snowfall Lib
    snowfall-lib = {
      url = "github:snowfallorg/lib/dev";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Snowfall Flake
    snowfall-flake = {
      url = "github:snowfallorg/flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    snowfall-frost = {
      url = "github:snowfallorg/frost";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    snowfall-thaw = {
      url = "github:snowfallorg/thaw";
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

  outputs =
    inputs:
    let
      inherit (inputs) deploy-rs nixpkgs snowfall-lib;

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
        permittedInsecurePackages = [ "freeimage-unstable-2021-11-01" ];
      };

      overlays = with inputs; [
        hypr-socket-watch.overlays.default
        # hyprlang.overlays.default
        hyprcursor.overlays.default
        # hypridle.overlays.default
        hyprland.overlays.default
        hyprlock.overlays.default
        # nixpkgs-wayland.overlay
        nix-ld-rs.overlays.default
        nur.overlay
        rust-overlay.overlays.default
        snowfall-flake.overlays.default
        snowfall-frost.overlays.default
        snowfall-thaw.overlays.default
      ];

      homes.modules = with inputs; [
        hypr-socket-watch.homeManagerModules.default
        hypridle.homeManagerModules.default
        hyprlock.homeManagerModules.default
        hyprpaper.homeManagerModules.default
        nixvim.homeManagerModules.nixvim
        sops-nix.homeManagerModules.sops
        spicetify-nix.homeManagerModules.default
      ];

      systems = {
        modules = {
          darwin = with inputs; [ nixvim.nixDarwinModules.nixvim ];

          nixos = with inputs; [
            lanzaboote.nixosModules.lanzaboote
            nixvim.nixosModules.nixvim
            sops-nix.nixosModules.sops
          ];
        };
      };

      deploy = lib.mkDeploy { inherit (inputs) self; };

      checks = builtins.mapAttrs (
        _system: deploy-lib: deploy-lib.deployChecks inputs.self.deploy
      ) deploy-rs.lib;

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
      formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-rfc-style;
    };
}
