{
  description = "KhaneliNix";

  outputs =
    inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./flake-modules
        # inputs.flake-parts.flakeModules.flakeModules
        # inputs.flake-parts.flakeModules.modules
      ];

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
        modules = {
          darwin = with inputs; [ sops-nix.darwinModules.sops ];
          homes = with inputs; [
            anyrun.homeManagerModules.default
            catppuccin.homeManagerModules.catppuccin
            hypr-socket-watch.homeManagerModules.default
            nix-index-database.hmModules.nix-index
            nur.hmModules.nur
            sops-nix.homeManagerModules.sops
          ];
          nixos = with inputs; [
            lanzaboote.nixosModules.lanzaboote
            sops-nix.nixosModules.sops
          ];
        };

        deploy = {
          inherit self;
        };
      };
    };

  inputs = {
    #          ╭──────────────────────────────────────────────────────────╮
    #          │                       Core System                        │
    #          ╰──────────────────────────────────────────────────────────╯
    darwin = {
      # url = "github:lnl7/nix-darwin";
      # NOTE: Upstream slow to respond to PRs, using own fork.
      url = "github:khaneliman/nix-darwin/cherry-picks";
      # url = "git+file:///Users/khaneliman/github/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    devshell.url = "github:numtide/devshell";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks-nix.url = "github:cachix/git-hooks.nix";
    home-manager.url = "github:nix-community/home-manager";
    # home-manager.url = "github:khaneliman/home-manager/thunderbird";
    # home-manager.url = "git+file:///home/khaneliman/Documents/github/home-manager";
    # home-manager.url = "git+file:///Users/khaneliman/Documents/github/home-manager";

    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.1"; # Secure boot
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    # FIXME: remove after upstream PRs are available
    nixpkgs-master.url = "github:nixos/nixpkgs";

    nixos-wsl = {
      url = "github:nix-community/nixos-wsl";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix.url = "github:Mic92/sops-nix"; # Secrets management
    treefmt-nix.url = "github:numtide/treefmt-nix";

    #          ╭──────────────────────────────────────────────────────────╮
    #          │                    System Deployment                     │
    #          ╰──────────────────────────────────────────────────────────╯
    deploy-rs.url = "github:serokell/deploy-rs";
    disko.url = "github:nix-community/disko/latest";

    #          ╭──────────────────────────────────────────────────────────╮
    #          │                       Applications                       │
    #          ╰──────────────────────────────────────────────────────────╯
    anyrun.url = "github:anyrun-org/anyrun";
    anyrun-nixos-options.url = "github:n3oney/anyrun-nixos-options";

    catppuccin-cursors.url = "github:catppuccin/cursors";
    catppuccin.url = "github:catppuccin/nix";

    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    hypr-socket-watch.url = "github:khaneliman/hypr-socket-watch";

    khanelivim = {
      url = "github:khaneliman/khanelivim";
      # url = "git+file:///Users/khaneliman/Documents/github/khanelivim";
      # url = "git+file:///home/khaneliman/Documents/github/khanelivim";
      inputs = {
        # nixpkgs.follows = "nixpkgs";
        git-hooks-nix.follows = "git-hooks-nix";
        snowfall-lib.follows = "snowfall-lib";
        snowfall-flake.follows = "snowfall-flake";
      };
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nur.url = "github:nix-community/NUR";
    snowfall-flake.url = "github:snowfallorg/flake";
    waybar.url = "github:Alexays/Waybar";
    wezterm.url = "github:wez/wezterm?dir=nix";

    yazi-plugins = {
      url = "github:yazi-rs/plugins";
      flake = false;
    };
  };

  # outputs =
  #   inputs:
  #   let
  #     inherit (inputs) snowfall-lib;
  #
  #     lib = snowfall-lib.mkLib {
  #       inherit inputs;
  #       src = ./.;
  #
  #       snowfall = {
  #         meta = {
  #           name = "khanelinix";
  #           title = "KhaneliNix";
  #         };
  #
  #         namespace = "khanelinix";
  #       };
  #     };
  #   in
  #   lib.mkFlake {
  #     channels-config = {
  #       # allowBroken = true;
  #       allowUnfree = true;
  #       # showDerivationWarnings = [ "maintainerless" ];
  #
  #       # TODO: cleanup when available
  #       permittedInsecurePackages = [
  #         # NOTE: needed by emulationstation
  #         "freeimage-unstable-2021-11-01"
  #         # dev shells
  #         "aspnetcore-runtime-6.0.36"
  #         "aspnetcore-runtime-7.0.20"
  #         "aspnetcore-runtime-wrapped-7.0.20"
  #         "aspnetcore-runtime-wrapped-6.0.36"
  #         "dotnet-combined"
  #         "dotnet-core-combined"
  #         "dotnet-runtime-6.0.36"
  #         "dotnet-runtime-7.0.20"
  #         "dotnet-runtime-wrapped-6.0.36"
  #         "dotnet-runtime-wrapped-7.0.20"
  #         "dotnet-sdk-6.0.428"
  #         "dotnet-sdk-7.0.410"
  #         "dotnet-sdk-wrapped-6.0.428"
  #         "dotnet-sdk-wrapped-7.0.410"
  #         "dotnet-wrapped-combined"
  #       ];
  #     };
  #
  #     overlays = [ ];
  #
  #     homes.modules = with inputs; [
  #       anyrun.homeManagerModules.default
  #       catppuccin.homeManagerModules.catppuccin
  #       hypr-socket-watch.homeManagerModules.default
  #       nix-index-database.hmModules.nix-index
  #       # FIXME:
  #       # nur.modules.homeManager.default
  #       sops-nix.homeManagerModules.sops
  #     ];
  #
  #     systems = {
  #       modules = {
  #         darwin = with inputs; [
  #           sops-nix.darwinModules.sops
  #         ];
  #         nixos = with inputs; [
  #           disko.nixosModules.disko
  #           lanzaboote.nixosModules.lanzaboote
  #           nix-flatpak.nixosModules.nix-flatpak
  #           sops-nix.nixosModules.sops
  #         ];
  #       };
  #     };
  #
  #     templates = {
  #       angular.description = "Angular template";
  #       c.description = "C flake template.";
  #       container.description = "Container template";
  #       cpp.description = "CPP flake template";
  #       dotnetf.description = "Dotnet FSharp template";
  #       flake-compat.description = "Flake-compat shell and default files.";
  #       go.description = "Go template";
  #       node.description = "Node template";
  #       python.description = "Python template";
  #       rust.description = "Rust template";
  #       rust-web-server.description = "Rust web server template";
  #       snowfall.description = "Snowfall-lib template";
  #     };
  #
  #     deploy = lib.mkDeploy { inherit (inputs) self; };
  #
  #     outputs-builder = channels: {
  #       formatter = inputs.treefmt-nix.lib.mkWrapper channels.nixpkgs ./treefmt.nix;
  #     };
  #   };
}
