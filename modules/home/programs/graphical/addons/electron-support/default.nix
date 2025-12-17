{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.graphical.addons.electron-support;
in
{
  options.khanelinix.programs.graphical.addons.electron-support = {
    enable = lib.mkEnableOption "wayland electron support in the desktop environment";
  };

  config = mkIf cfg.enable {
    home.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    };

    xdg.configFile."electron-flags.conf".text = /* Bash */ ''
      --enable-features=UseOzonePlatform,WaylandWindowDecorations
      --ozone-platform=wayland
      --ozone-platform-hint=wayland
    '';
  };
}
