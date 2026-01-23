{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    getExe
    getExe'
    ;
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.display-managers.regreet;
  themeCfg = config.khanelinix.theme;
  gtkCfg = config.khanelinix.desktop.addons.gtk;

  greetdHyprlandConfig = pkgs.writeText "greetd-hyprland-config" ''
    ${cfg.hyprlandOutput}

    animations {
      enabled=false
      first_launch_animation=false
    }

    bind=SUPER, RETURN, exec, ${getExe pkgs.wezterm}
    bind=SUPER_SHIFT, RETURN, exec, ${getExe pkgs.nwg-hello}
    bind=SUPER_CTRL_SHIFT, RETURN, exec, ${getExe pkgs.greetd.regreet}

    exec-once = ${lib.getExe' pkgs.dbus "dbus-update-activation-environment"} --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE

    exec-once = ${getExe pkgs.greetd.regreet} -l debug && ${getExe' pkgs.hyprland-unwrapped "hyprctl"} exit
  '';
in
{
  options.khanelinix.display-managers.regreet = with types; {
    enable = lib.mkEnableOption "greetd";
    hyprlandOutput = mkOpt lines "" "Hyprlands Outputs config.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      themeCfg.cursor.package
      themeCfg.icon.package
      gtkCfg.theme.package
    ];

    programs.regreet = {
      enable = true;

      settings = {
        background = {
          path = lib.khanelinix.theme.wallpaperPath {
            inherit config pkgs;
            name = config.khanelinix.theme.wallpaper.primary;
          };
          fit = "Cover";
        };

        GTK = {
          application_prefer_dark_theme = true;
          cursor_theme_name = "${themeCfg.cursor.name}";
          font_name = "${config.khanelinix.system.fonts.default} * 12";
          icon_theme_name = "${themeCfg.icon.name}";
          theme_name = "${gtkCfg.theme.name}";
        };
      };
    };

    services.greetd = {
      settings = {
        default_session = {
          command = "${getExe pkgs.hyprland-unwrapped} --config ${greetdHyprlandConfig} > /tmp/hyprland-log-out.txt 2>&1";
        };
      };

      restart = false;
    };

    security.pam.services.greetd = {
      enableGnomeKeyring = true;
      gnupg.enable = true;
    };
  };
}
