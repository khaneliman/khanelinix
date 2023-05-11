{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.khanelinix.tools.icehouse;

  inherit (lib) mkEnableOption mkIf;
in {
  options.khanelinix.tools.icehouse = {
    enable = mkEnableOption "Icehouse";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [pkgs.snowfallorg.icehouse];
  };
}
