{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) getExe mkIf;

  cfg = config.${namespace}.programs.graphical.addons.gamescope;
in
{
  options.${namespace}.programs.graphical.addons.gamescope = {
    enable = lib.mkEnableOption "gamescope";
  };

  config = mkIf cfg.enable {
    programs.gamescope = {
      enable = true;
      package = pkgs.gamescope;
    };

    security.wrappers.gamescope = {
      owner = "root";
      group = "root";
      source = "${getExe config.programs.gamescope.package}";
      capabilities = "cap_sys_ptrace,cap_sys_nice+pie";
    };
  };
}
