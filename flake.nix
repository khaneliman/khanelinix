{
  description = "KhaneliNix";

  inputs = {
    # TODO: utilize these
    # agenix.url = "github:ryantm/agenix";
    # agenix.inputs.nixpkgs.follows = "nixpkgs";
    # agenix.inputs.darwin.follows = "darwin";
    # agenix.inputs.home-manager.follows = "home-manager";

    # Astronvim repo
    astronvim = {
      url = "github:AstroNvim/AstroNvim/nightly";
      flake = false;
    };

    # Personal astronvim configuration
    astronvim-user = {
      url = "github:khaneliman/astronvim";
      flake = false;
    };

    # Comma
    comma.url = "github:nix-community/comma";
    comma.inputs.nixpkgs.follows = "nixpkgs";

    # macOS Support (master)
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    # System Deployment
    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";

    # Snowfall Flake
    flake.url = "github:snowfallorg/flake";
    flake.inputs.nixpkgs.follows = "nixpkgs";

    # GPG default configuration
    gpg-base-conf = {
      url = "github:drduh/config";
      flake = false;
    };

    # flake.inputs.snowfall-lib.follows = "snowfall-lib"; 
    # Home Manager (master)
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # hyprland
    hyprland.url = "github:hyprwm/Hyprland/unsafe-state-reworks";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";

    # Hyprland user contributions flake
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixPkgs (nixos-unstable)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Nix User Repository (master)
    nur.url = "github:nix-community/NUR";

    # Hardware Configuration
    nixos-hardware.url = "github:nixos/nixos-hardware";

    # Generate System Images
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";

    # NixOS WSL Support
    nixos-wsl.url = "github:nix-community/nixos-wsl";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    # Snowfall Lib
    # TODO: replace with main branch after home-manager merged
    snowfall-lib.url = "github:snowfallorg/lib/dev";
    snowfall-lib.inputs.nixpkgs.follows = "nixpkgs";

    # Run unpatched dynamically compiled binaries
    nix-ld.url = "github:Mic92/nix-ld";
    nix-ld.inputs.nixpkgs.follows = "nixpkgs";

    ## Ranger plugins
    ranger-devicons.url = "github:alexanderjeurissen/ranger_devicons";
    ranger-devicons.flake = false;

    ranger-udisk-menu.url = "github:SL-RU/ranger_udisk_menu";
    ranger-udisk-menu.flake = false;

    # rust overlay
    rustup-overlay.url = "github:oxalica/rust-overlay";
    rustup-overlay.inputs.nixpkgs.follows = "nixpkgs";

    # Nerd font 
    sf-mono-nerd-font.url = "github:shaunsingh/SFMono-Nerd-Font-Ligaturized";
    sf-mono-nerd-font.flake = false;

    spicetify-nix.url = "github:the-argus/spicetify-nix/dev";
    spicetify-nix.inputs.nixpkgs.follows = "nixpkgs";

    # Yubikey Guide
    yubikey-guide = {
      url = "github:drduh/YubiKey-Guide";
      flake = false;
    };
  };

  outputs = inputs:
    let
      lib = inputs.snowfall-lib.mkLib {
        inherit inputs;
        src = ./.;
      };
    in
    lib.mkFlake {
      package-namespace = "khanelinix";

      channels-config.allowUnfree = true;
      # TODO: cleanup when available
      channels-config.permittedInsecurePackages = [
        "imagemagick-6.9.12-68"
        "openssl-1.1.1v"
      ];
      # channels-config.allowBroken = true;

      # overlays from inputs
      overlays = with inputs; [
        devshell.overlays.default
        flake.overlay
        hyprland.overlays.default
        nur.overlay
        rustup-overlay.overlays.default
        # agenix.overlays.default
      ];

      # nixos modules
      systems.modules.nixos = with inputs; [
        # agenix.nixosModules.default
        home-manager.nixosModules.home-manager
        nix-ld.nixosModules.nix-ld
      ];

      # home-manager modules
      systems.modules.home = with inputs; [
        # agenix.homeManagerModules.default
        home-manager.homeModules.home-manager
      ];

      # nix-darwin modules
      systems.modules.darwin = with inputs; [
        # agenix.darwinModules.default
        home-manager.darwinModules.home-manager
      ];

      deploy = lib.mkDeploy { inherit (inputs) self; };

      checks =
        builtins.mapAttrs
          (_system: deploy-lib:
            deploy-lib.deployChecks inputs.self.deploy)
          inputs.deploy-rs.lib;
    };
}

