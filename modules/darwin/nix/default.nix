{ config
, lib
, ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.nix;
in
{
  imports = [ ../../shared/nix/default.nix ];

  config = mkIf cfg.enable {
    nix = {
      settings = {
        extra-nix-path = "nixpkgs=flake:nixpkgs";
        build-users-group = "nixbld";
      };

      gc = {
        interval = { Day = 7; };
        user = config.khanelinix.user.name;
      };
    };
  };
}
