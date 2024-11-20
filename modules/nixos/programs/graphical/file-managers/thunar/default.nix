{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.programs.graphical.file-managers.thunar;
in
{
  options.khanelinix.programs.graphical.file-managers.thunar = {
    enable = mkBoolOpt false "Whether to enable the xfce file manager.";
  };

  config = mkIf cfg.enable {
    programs.thunar = {
      enable = true;
    };
  };
}
