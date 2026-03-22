{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv.hostPlatform) isLinux;

  cfg = config.khanelinix.programs.graphical.addons.electron-support;
in
{
  options.khanelinix.programs.graphical.addons.electron-support = {
    enable = lib.mkEnableOption "wayland electron support in the desktop environment";
  };

  config = lib.mkMerge [
    (mkIf cfg.enable {
      assertions = [
        {
          assertion = isLinux;
          message = "Wayland electron support is only available on linux";
        }
      ];
    })
    (mkIf (cfg.enable && isLinux) {
      home.sessionVariables = {
        NIXOS_OZONE_WL = "1";
        ELECTRON_OZONE_PLATFORM_HINT = "wayland";
      };

      xdg.configFile."electron-flags.conf".text = /* Bash */ ''
        --enable-features=UseOzonePlatform,WaylandWindowDecorations
        --ozone-platform=wayland
        --ozone-platform-hint=wayland
      '';
    })
  ];
}
