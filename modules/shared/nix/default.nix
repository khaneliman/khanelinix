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
      khanelinix.nixos-revision
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
