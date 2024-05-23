{
  config,
  inputs,
  lib,
  pkgs,
  system,
  namespace,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    getExe
    getExe'
    ;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  inherit (inputs) hyprland;

  cfg = config.${namespace}.display-managers.regreet;
  themeCfg = config.${namespace}.theme;
  gtkCfg = config.${namespace}.desktop.addons.gtk;

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
  options.${namespace}.display-managers.regreet = with types; {
    enable = mkBoolOpt false "Whether or not to enable greetd.";
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
          path = pkgs.${namespace}.wallpapers.flatppuccin_macchiato;
          fit = "Cover";
        };

        GTK = {
          application_prefer_dark_theme = true;
          cursor_theme_name = "${themeCfg.cursor.name}";
          font_name = "${config.${namespace}.system.fonts.default} * 12";
          icon_theme_name = "${themeCfg.icon.name}";
          theme_name = "${gtkCfg.theme.name}";
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
