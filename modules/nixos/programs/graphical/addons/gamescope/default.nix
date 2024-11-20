{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) getExe mkIf;
  inherit (lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.programs.graphical.addons.gamescope;
in
{
  options.khanelinix.programs.graphical.addons.gamescope = {
    enable = mkBoolOpt false "Whether or not to enable gamescope.";
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
