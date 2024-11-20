{
  description = "KhaneliNix";

  inputs = {
    # Principle Inputs
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager.url = "github:nix-community/home-manager";
    # home-manager.url = "git+file:///home/khaneliman/Documents/github/home-manager";
    # home-manager.url = "git+file:///Users/khaneliman/Documents/github/home-manager";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixos-wsl = {
      url = "github:nix-community/nixos-wsl";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix.url = "github:Mic92/sops-nix";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Application inputs
    anyrun.url = "github:anyrun-org/anyrun";
    anyrun-nixos-options.url = "github:n3oney/anyrun-nixos-options";
    catppuccin.url = "github:catppuccin/nix";
    catppuccin-cursors.url = "github:catppuccin/cursors";
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
      url = "github:khaneliman/khanelivim";
      # url = "git+file:///Users/khaneliman/Documents/github/khanelivim";
      # url = "git+file:///home/khaneliman/Documents/github/khanelivim";
      inputs = {
        # nixpkgs.follows = "nixpkgs";
        pre-commit-hooks-nix.follows = "pre-commit-hooks-nix";
        snowfall-flake.follows = "snowfall-flake";
      };
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur.url = "github:nix-community/NUR";
    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
    snowfall-flake = {
      url = "github:snowfallorg/flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    waybar = {
      url = "github:Alexays/Waybar";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wezterm.url = "github:wez/wezterm?dir=nix";
  };

  outputs =
    inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ ./flake-modules ];

      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      flake = {
        #   channels-config = {
        #     allowUnfree = true;
        #     permittedInsecurePackages = [
        #       "freeimage-unstable-2021-11-01"
        #     ];
        #   };
        #
        #   homes.modules = with inputs; [
        #     anyrun.homeManagerModules.default
        #     catppuccin.homeManagerModules.catppuccin
        #     hypr-socket-watch.homeManagerModules.default
        #     nix-index-database.hmModules.nix-index
        #     nur.hmModules.nur
        #     sops-nix.homeManagerModules.sops
        #   ];
        #
        #   systems = {
        #     modules = {
        #       darwin = with inputs; [ sops-nix.darwinModules.sops ];
        #       nixos = with inputs; [
        #         lanzaboote.nixosModules.lanzaboote
        #         sops-nix.nixosModules.sops
        #       ];
        #     };
        #   };
        #
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

        deploy = {
          inherit self;
        };
      };
    };
}
