{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.programs.graphical.addons.electron-support;
in
{
  options.${namespace}.programs.graphical.addons.electron-support = {
    enable = lib.mkEnableOption "wayland electron support in the desktop environment";
  };

  config = mkIf cfg.enable {
    home.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

    xdg.configFile."electron-flags.conf".source = ./electron-flags.conf;
  };
}
