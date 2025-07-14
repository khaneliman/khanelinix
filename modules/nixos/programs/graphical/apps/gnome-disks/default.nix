{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.graphical.apps.gnome-disks;
in
{
  options.khanelinix.programs.graphical.apps.gnome-disks = {
    enable = lib.mkEnableOption "gnome-disks";
  };

  config = mkIf cfg.enable {
    programs.gnome-disks = {
      enable = true;
    };
  };
}
