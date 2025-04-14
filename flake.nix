{
  description = "KhaneliNix";

  inputs = {
    # Core inputs
    darwin = {
      # url = "github:lnl7/nix-darwin";
      url = "github:khaneliman/nix-darwin/darwin-rewrite";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    ez-configs.url = "github:ehllie/ez-configs";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixos-wsl = {
      url = "github:nix-community/nixos-wsl";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        # Optional inputs removed
        flake-compat.follows = "";
      };
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        # Optional inputs removed
        flake-compat.follows = "";
      };
    };
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        # Optional inputs removed
        gitignore.follows = "";
        flake-compat.follows = "";
      };
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs = {
        # Does this even make sense with a pinned version ?
        nixpkgs.follows = "nixpkgs";
        pre-commit-hooks-nix.follows = "git-hooks-nix";
        # Optional inputs removed
        flake-compat.follows = "";
      };
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Applications
    anyrun = {
      url = "github:anyrun-org/anyrun";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    anyrun-nixos-options.url = "github:n3oney/anyrun-nixos-options";
    catppuccin-cursors = {
      url = "github:catppuccin/cursors";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        pre-commit-hooks.follows = "git-hooks-nix";
      };
    };
    hypr-socket-watch.url = "github:khaneliman/hypr-socket-watch";
    khanelivim.url = "github:khaneliman/khanelivim";
    # nh.url = "github:viperML/nh";
    nh.url = "github:khaneliman/nh/darwin";
    nix-flatpak.url = "github:gmodena/nix-flatpak/latest";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    waybar = {
      # url = "github:Alexays/Waybar";
      # TODO: remove after https://github.com/Alexays/Waybar/pull/4045 or similar is merged.
      url = "github:khaneliman/Waybar/pulse";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        # Optional inputs removed
        flake-compat.follows = "";
      };
    };
    yazi-flavors = {
      url = "github:yazi-rs/flavors";
      flake = false;
    };

    nixpkgs-master.url = "github:NixOS/nixpkgs";
  };

  outputs =
    {
      flake-parts,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      imports = [
        ./flake
      ];
    };
}
