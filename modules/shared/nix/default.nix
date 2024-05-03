{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types mkDefault mkIf;
  inherit (lib.internal) mkBoolOpt mkOpt;

  cfg = config.khanelinix.nix;
in
{
  options.khanelinix.nix = with types; {
    enable = mkBoolOpt true "Whether or not to manage nix configuration.";
    package = mkOpt package pkgs.nixVersions.latest "Which nix package to use.";
  };

  config = mkIf cfg.enable {
    # faster rebuilding
    documentation = {
      doc.enable = false;
      info.enable = false;
      man.enable = mkDefault true;
    };

    environment = {
      etc = with inputs; {
        # set channels (backwards compatibility)
        "nix/flake-channels/system".source = self;
        "nix/flake-channels/nixpkgs".source = nixpkgs;
        "nix/flake-channels/home-manager".source = home-manager;

        # preserve current flake in /etc
        "nixos/flake".source = self;
      };

      systemPackages = with pkgs; [
        cachix
        deploy-rs
        git
        nix-prefetch-git
      ];
    };

    nix =
      let
        users = [
          "root"
          config.khanelinix.user.name
        ];
      in
      {
        inherit (cfg) package;

        gc = {
          automatic = true;
          options = "--delete-older-than 7d";
        };

        settings = {
          allowed-users = users;
          auto-optimise-store = true;
          experimental-features = "nix-command flakes";
          http-connections = 50;
          keep-derivations = true;
          keep-outputs = true;
          log-lines = 50;
          sandbox = "relaxed";
          trusted-users = users;
          warn-dirty = false;

          substituters = [
            "https://cache.nixos.org"
            "https://khanelinix.cachix.org"
            "https://nix-community.cachix.org"
            "https://nixpkgs-unfree.cachix.org"
            "https://numtide.cachix.org"
          ];

          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "khanelinix.cachix.org-1:FTmbv7OqlMsmJEOFvAlz7PVkoGtstbwLC2OldAiJZ10="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
            "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
          ];
        };

        # flake-utils-plus
        generateNixPathFromInputs = true;
        generateRegistryFromInputs = true;
        linkInputs = true;
      };
  };
}
