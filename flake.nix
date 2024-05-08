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

    # Hypridle
    hypridle.url = "github:hyprwm/Hypridle";
    # url = "git+file:///home/khaneliman/Documents/github/hypridle";

    # Hyprlock
    hyprlock = {
      url = "github:hyprwm/Hyprlock";
      # NOTE: required to prevent red screen on lock
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";

    # Hyprpaper
    hyprpaper.url = "github:hyprwm/hyprpaper";

    # Hyprland user contributions flake
    hyprland-contrib.url = "github:hyprwm/contrib";

    # Hyprland plugins
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    # Hyprland socket watcher
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

    # Weekly updating nix-index database
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
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

    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";

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
      inherit (inputs) deploy-rs snowfall-lib;

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
        nix-ld-rs.overlays.default
        nur.overlay
      ];

      homes.modules = with inputs; [
        hypr-socket-watch.homeManagerModules.default
        hyprlock.homeManagerModules.default
        hyprpaper.homeManagerModules.default
        nix-index-database.hmModules.nix-index
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

      outputs-builder = channels: {
        checks.pre-commit-check = inputs.pre-commit-hooks-nix.lib.${channels.nixpkgs.system}.run {
          src = ./.;
          hooks =
            let
              excludes = [
                "flake.lock"
                "CHANGELOG.md"
              ];
              fail_fast = true;
              verbose = true;
            in
            {
              actionlint.enable = true;
              clang-format.enable = true;
              clang-tidy.enable = true;
              # conform.enable = true;

              deadnix = {
                enable = true;

                settings = {
                  edit = true;
                };
              };

              eslint = {
                enable = true;
                package = channels.nixpkgs.eslint_d;
              };

              git-cliff = {
                enable = false;
                inherit excludes fail_fast verbose;

                always_run = true;
                description = "pre-push hook for git-cliff";
                entry = "${channels.nixpkgs.khanelinix.git-cliff}/bin/git-cliff";
                language = "system";
                stages = [ "pre-push" ];
              };

              luacheck.enable = true;

              nixfmt = {
                enable = true;
                package = channels.nixpkgs.nixfmt-rfc-style;
              };

              pre-commit-hook-ensure-sops.enable = true;

              prettier = {
                enable = true;
                inherit excludes fail_fast verbose;

                description = "pre-commit hook for prettier";
                settings = {
                  binPath = "${channels.nixpkgs.prettierd}/bin/prettierd";
                  write = true;
                };
              };

              shfmt.enable = true;
              statix.enable = true;
              # treefmt.enable = true;
            };
        };

        formatter = channels.nixpkgs.nixfmt-rfc-style;
      };
    };
}
