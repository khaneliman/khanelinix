{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.programs.graphical.apps.gnome-disks;
in
{
  options.${namespace}.programs.graphical.apps.gnome-disks = {
    enable = lib.mkEnableOption "gnome-disks";
  };

  config = mkIf cfg.enable {
    programs.gnome-disks = {
      enable = true;
    };
  };
}
