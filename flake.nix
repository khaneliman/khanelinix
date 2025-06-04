{
  description = "KhaneliNix";

  inputs = {
    # Core inputs
    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixos-wsl = {
      url = "github:nix-community/nixos-wsl";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        # Optional inputs removed
        flake-compat.follows = "";
      };
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:NixOS/nixpkgs";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nix-rosetta-builder = {
      # url = "github:cpick/nix-rosetta-builder";
      url = "github:khaneliman/nix-rosetta-builder/speedfactor";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
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

    # Applications
    anyrun-nixos-options.url = "github:n3oney/anyrun-nixos-options";
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hypr-socket-watch.url = "github:khaneliman/hypr-socket-watch";
    khanelivim.url = "github:khaneliman/khanelivim";
    nh.url = "github:nix-community/nh";
    nix-flatpak.url = "github:gmodena/nix-flatpak/latest";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    stylix = {
      url = "github:danth/stylix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        git-hooks.follows = "git-hooks-nix";
        home-manager.follows = "home-manager";
        # Optional inputs removed
        flake-compat.follows = "";
      };
    };
    waybar = {
      url = "github:Alexays/Waybar";
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

    # TODO:
    # Dev flake
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        # Optional inputs removed
        gitignore.follows = "";
        flake-compat.follows = "";
      };
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
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
