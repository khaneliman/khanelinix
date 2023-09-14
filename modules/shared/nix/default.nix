{ options
, config
, pkgs
, lib
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt mkOpt;
  cfg = config.khanelinix.nix;
in
{
  options.khanelinix.nix = with types; {
    enable = mkBoolOpt true "Whether or not to manage nix configuration.";
    package = mkOpt package pkgs.nixUnstable "Which nix package to use.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      cachix
      deploy-rs
      nix-index
      nix-prefetch-git
    ];

    nix =
      let
        users = [ "root" config.khanelinix.user.name ];
      in
      {
        inherit (cfg) package;

        settings = {
          allowed-users = users;
          auto-optimise-store = true;
          experimental-features = "nix-command flakes";
          http-connections = 50;
          log-lines = 50;
          sandbox = "relaxed";
          trusted-users = users;
          warn-dirty = false;
          keep-derivations = true;
          keep-outputs = true;
          substituters = [
            "https://cache.nixos.org"
            "https://nix-community.cachix.org"
          ];
          trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          ];

        };

        gc = {
          automatic = true;
          options = "--delete-older-than 30d";
        };

        # flake-utils-plus
        generateNixPathFromInputs = true;
        generateRegistryFromInputs = true;
        linkInputs = true;
      };
  };
}
