{
  description = "KhaneliNix";

  inputs = {
    # Core inputs
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    home-manager.url = "github:nix-community/home-manager";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixos-wsl = {
      url = "github:nix-community/nixos-wsl";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs.url = "github:serokell/deploy-rs";
    disko.url = "github:nix-community/disko/latest";
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
    khanelivim = {
      url = "github:khaneliman/khanelivim";
      inputs = {
        yazi.follows = "yazi";
        git-hooks-nix.follows = "git-hooks-nix";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/latest";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    snowfall-flake = {
      url = "github:snowfallorg/flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        snowfall-lib.follows = "snowfall-lib";
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
    yazi = {
      url = "github:sxyazi/yazi";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    yazi-plugins = {
      url = "github:yazi-rs/plugins";
      flake = false;
    };
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
        # showDerivationWarnings = [ "maintainerless" ];

        # TODO: cleanup when available
        permittedInsecurePackages = [
          # NOTE: needed by emulationstation
          "freeimage-unstable-2021-11-01"
          # dev shells
          "aspnetcore-runtime-6.0.36"
          "aspnetcore-runtime-7.0.20"
          "aspnetcore-runtime-wrapped-7.0.20"
          "aspnetcore-runtime-wrapped-6.0.36"
          "dotnet-combined"
          "dotnet-core-combined"
          "dotnet-runtime-6.0.36"
          "dotnet-runtime-7.0.20"
          "dotnet-runtime-wrapped-6.0.36"
          "dotnet-runtime-wrapped-7.0.20"
          "dotnet-sdk-6.0.428"
          "dotnet-sdk-7.0.410"
          "dotnet-sdk-wrapped-6.0.428"
          "dotnet-sdk-wrapped-7.0.410"
          "dotnet-wrapped-combined"
        ];
      };

      overlays = [ ];

      homes.modules = with inputs; [
        anyrun.homeManagerModules.default
        catppuccin.homeManagerModules.catppuccin
        hypr-socket-watch.homeManagerModules.default
        nix-index-database.hmModules.nix-index
        sops-nix.homeManagerModules.sops
      ];

      systems = {
        modules = {
          darwin = with inputs; [
            sops-nix.darwinModules.sops
          ];
          nixos = with inputs; [
            disko.nixosModules.disko
            lanzaboote.nixosModules.lanzaboote
            nix-flatpak.nixosModules.nix-flatpak
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

      outputs-builder = channels: {
        formatter = inputs.treefmt-nix.lib.mkWrapper channels.nixpkgs ./treefmt.nix;
      };
    };
}
