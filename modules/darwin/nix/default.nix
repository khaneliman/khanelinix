{ config
, lib
, ...
}:
let
  inherit (lib) mkIf mkForce;

  cfg = config.khanelinix.nix;
in
{
  imports = [ ../../shared/nix/default.nix ];

  config = mkIf cfg.enable {
    nix = {
      gc = {
        interval = { Day = 7; };
        user = config.khanelinix.user.name;
      };

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
        # FIX: shouldn't disable, but getting sandbox max size errors on darwin
        sandbox = mkForce false;
      };
    };
  };
}
