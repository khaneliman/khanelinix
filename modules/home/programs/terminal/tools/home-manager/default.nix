{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.internal) enabled;

  cfg = config.khanelinix.programs.terminal.tools.home-manager;
in
{
  options.khanelinix.programs.terminal.tools.home-manager = {
    enable = mkEnableOption "home-manager";
  };

  config = mkIf cfg.enable { programs.home-manager = enabled; };
}
