{ config, lib, ... }:
let
  inherit (lib) mkIf mkForce;

  cfg = config.khanelinix.nix;
in
{
  imports = [ ../../shared/nix/default.nix ];

  config = mkIf cfg.enable {
    nix = {
      # Options that aren't supported through nix-darwin
      extraOptions = ''
        # bail early on missing cache hits
        connect-timeout = 5
        keep-going = true
      '';

      gc = {
        interval = {
          Day = 7;
          Hour = 3;
        };
        user = config.khanelinix.user.name;
      };

      optimise = {
        interval = {
          Day = 7;
          Hour = 4;
        };
        user = config.khanelinix.user.name;
      };

      # NOTE: not sure if i saw any benefits changing this
      # daemonProcessType = "Adaptive";

      settings = {
        build-users-group = "nixbld";
        extra-nix-path = "nixpkgs=flake:nixpkgs";
        extra-sandbox-paths = [
          "/System/Library/Frameworks"
          "/System/Library/PrivateFrameworks"
          "/usr/lib"
          "/private/tmp"
          "/private/var/tmp"
          "/usr/bin/env"
        ];

        # Frequent issues with networking failures on darwin
        # limit number to see if it helps
        http-connections = mkForce 25;

        # FIX: shouldn't disable, but getting sandbox max size errors on darwin
        # darwin-rebuild --rollback on testing changing
        sandbox = mkForce false;
      };
    };
  };
}
