{ config
, lib
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.nix;
in
{
  options.khanelinix.nix = {
    enable = mkBoolOpt true "Whether or not to manage nix configuration.";
  };

  # TODO: remove module? 
  config = mkIf cfg.enable {
    sops.secrets.nix = {
      sopsFile = ../../../secrets/khaneliman/default.json;
      path = "${config.home.homeDirectory}/.config/nix/nix.conf";
    };
  };
}
