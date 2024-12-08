{
  description = "KhaneliNix";

  inputs = {
    anyrun.url = "github:anyrun-org/anyrun";
    anyrun-nixos-options.url = "github:n3oney/anyrun-nixos-options";

    catppuccin-cursors.url = "github:catppuccin/cursors";
    catppuccin.url = "github:catppuccin/nix";

    # macOS Support (master)
    darwin = {
      # url = "github:lnl7/nix-darwin";
      url = "github:khaneliman/nix-darwin/spacer";
      # url = "git+file:///Users/khaneliman/github/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # System Deployment
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager (master)
    home-manager.url = "github:nix-community/home-manager";
    # home-manager.url = "git+file:///home/khaneliman/Documents/github/home-manager";
    # home-manager.url = "git+file:///Users/khaneliman/Documents/github/home-manager";

    ##
    # Hyprland Section
    ##
    hyprland = {
      url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
      # url = "git+https://github.com/khaneliman/Hyprland?ref=windows&submodules=1";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    hypridle = {
      url = "github:hyprwm/Hypridle";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprlock = {
      url = "github:hyprwm/Hyprlock";
      # url = "git+file:///home/khaneliman/Documents/github/hypridle";
      inputs.nixpkgs.follows = "hyprland/nixpkgs";
    };
    hyprpaper = {
      url = "github:hyprwm/hyprpaper";
      inputs.nixpkgs.follows = "hyprland/nixpkgs";
    };
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "hyprland/nixpkgs";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    # Hyprland socket watcher
    hypr-socket-watch = {
      url = "github:khaneliman/hypr-socket-watch";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Personal Neovim Flake
    khanelivim = {
      # url = "github:khaneliman/khanelivim";
      url = "github:khaneliman/khanelivim/lazy";
      # url = "git+file:///Users/khaneliman/Documents/github/khanelivim";
      # url = "git+file:///home/khaneliman/Documents/github/khanelivim";

      inputs = {
        # nixpkgs.follows = "nixpkgs";
        pre-commit-hooks-nix.follows = "pre-commit-hooks-nix";
        snowfall-lib.follows = "snowfall-lib";
        snowfall-flake.follows = "snowfall-flake";
      };
    };

    # Secure boot
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Weekly updating nix-index database
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixPkgs (nixos-unstable)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # NixPkgs (nixpkgs-unstable)
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # NixOS WSL Support
    nixos-wsl = {
      url = "github:nix-community/nixos-wsl";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix User Repository (master)
    nur.url = "github:nix-community/NUR";

    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";

    # Snowfall Lib
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Snowfall Flake
    snowfall-flake = {
      url = "github:snowfallorg/flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Sops (Secrets)
    sops-nix = {
      url = "github:Mic92/sops-nix";
    };

    waybar = {
      url = "github:Alexays/Waybar";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wezterm.url = "github:wez/wezterm?dir=nix";
  };

  outputs =
    inputs:
    let
      inherit (inputs) snowfall-lib;

      lib = snowfall-lib.mkLib {
        inherit inputs;
        src = ./.;

        snowfall = {
          meta = {
            name = "khanelinix";
            title = "KhaneliNix";
          };

          namespace = "khanelinix";
        };
      };
    in
    lib.mkFlake {
      channels-config = {
        # allowBroken = true;
        allowUnfree = true;

        # TODO: cleanup when available
        permittedInsecurePackages = [
          # NOTE: needed by emulationstation
          "freeimage-unstable-2021-11-01"
        ];
      };

      overlays = [ ];

      homes.modules = with inputs; [
        anyrun.homeManagerModules.default
        catppuccin.homeManagerModules.catppuccin
        hypr-socket-watch.homeManagerModules.default
        nix-index-database.hmModules.nix-index
        # FIXME:
        # nur.modules.homeManager.default
        sops-nix.homeManagerModules.sops
      ];

      systems = {
        modules = {
          darwin = with inputs; [ sops-nix.darwinModules.sops ];
          nixos = with inputs; [
            disko.nixosModules.disko
            lanzaboote.nixosModules.lanzaboote
            sops-nix.nixosModules.sops
          ];
        };
      };

      templates = {
        angular.description = "Angular template";
        c.description = "C flake template.";
        container.description = "Container template";
        cpp.description = "CPP flake template";
        dotnetf.description = "Dotnet FSharp template";
        flake-compat.description = "Flake-compat shell and default files.";
        go.description = "Go template";
        node.description = "Node template";
        python.description = "Python template";
        rust.description = "Rust template";
        rust-web-server.description = "Rust web server template";
        snowfall.description = "Snowfall-lib template";
      };

      deploy = lib.mkDeploy { inherit (inputs) self; };

      outputs-builder = channels: { formatter = channels.nixpkgs.nixfmt-rfc-style; };
    };
}
