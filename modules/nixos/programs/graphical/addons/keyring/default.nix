{ config, lib, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.programs.graphical.addons.keyring;
in
{
  options.khanelinix.programs.graphical.addons.keyring = {
    enable = mkBoolOpt false "Whether to enable the passwords application.";
  };

  config = mkIf cfg.enable { programs.seahorse.enable = true; };
}
