{
  config,
  inputs,
  lib,
  pkgs,
  system,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    getExe
    getExe'
    ;
  inherit (lib.internal) mkBoolOpt mkOpt;
  inherit (inputs) hyprland;

  cfg = config.khanelinix.display-managers.regreet;

  greetdHyprlandConfig = pkgs.writeText "greetd-hyprland-config" ''
    ${cfg.hyprlandOutput}

    animations {
      enabled=false
      first_launch_animation=false
    }

    bind=SUPER, RETURN, exec, ${getExe pkgs.wezterm}
    bind=SUPER_SHIFT, RETURN, exec, ${getExe pkgs.nwg-hello}
    bind=SUPER_CTRL_SHIFT, RETURN, exec, ${getExe pkgs.greetd.regreet}

    exec-once = ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE

    exec-once = ${getExe pkgs.greetd.regreet} -l debug && ${
      getExe' hyprland.packages.${system}.hyprland-unwrapped "hyprctl"
    } exit
  '';
in
{
  options.khanelinix.display-managers.regreet = with types; {
    enable = mkBoolOpt false "Whether or not to enable greetd.";
    hyprlandOutput = mkOpt lines "" "Hyprlands Outputs config.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      config.khanelinix.desktop.addons.gtk.cursor.pkg
      config.khanelinix.desktop.addons.gtk.icon.pkg
      config.khanelinix.desktop.addons.gtk.theme.pkg
    ];

    programs.regreet = {
      enable = true;

      settings = {
        background = {
          path = pkgs.khanelinix.wallpapers.flatppuccin_macchiato;
          fit = "Cover";
        };

        GTK = {
          application_prefer_dark_theme = true;
          cursor_theme_name = "${config.khanelinix.desktop.addons.gtk.cursor.name}";
          font_name = "${config.khanelinix.system.fonts.default} * 12";
          icon_theme_name = "${config.khanelinix.desktop.addons.gtk.icon.name}";
          theme_name = "${config.khanelinix.desktop.addons.gtk.theme.name}";
        };
      };
    };

    services.greetd = {
      settings = {
        default_session = {
          command = "${
            getExe hyprland.packages.${system}.hyprland-unwrapped
          } --config ${greetdHyprlandConfig} > /tmp/hyprland-log-out.txt 2>&1";
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
