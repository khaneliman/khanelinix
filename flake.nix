{
  description = "KhaneliNix";

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
        homes.modules = with inputs; [
          anyrun.homeManagerModules.default
          catppuccin.homeManagerModules.catppuccin
          hypr-socket-watch.homeManagerModules.default
          nix-index-database.hmModules.nix-index
          nur.hmModules.nur
          sops-nix.homeManagerModules.sops
        ];

        systems = {
          modules = {
            darwin = with inputs; [ sops-nix.darwinModules.sops ];
            nixos = with inputs; [
              lanzaboote.nixosModules.lanzaboote
              sops-nix.nixosModules.sops
            ];
          };
        };

        deploy = {
          inherit self;
        };
      };
    };

  inputs = {
    # Principle Inputs
    darwin = {
      # url = "github:lnl7/nix-darwin";
      url = "github:khaneliman/nix-darwin/spacer";
      # url = "git+file:///Users/khaneliman/github/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    devshell = {
      url = "github:numtide/devshell";
    };
    disko = {
      url = "github:nix-community/disko/latest";
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
    # Hyprland socket watcher
    hypr-socket-watch = {
      url = "github:khaneliman/hypr-socket-watch";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Personal Neovim Flake
    khanelivim = {
      url = "github:khaneliman/khanelivim";
      # url = "github:khaneliman/khanelivim/lazy";
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

    yazi-plugins = {
      url = "github:yazi-rs/plugins";
      flake = false;
    };
  };
}
