{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) types mkIf getExe getExe';
  inherit (lib.internal) mkBoolOpt mkOpt;

  cfg = config.khanelinix.display-managers.regreet;
  greetdSwayConfig = pkgs.writeText "greetd-sway-config" ''
    exec dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK
    exec systemctl --user import-environment

    ${cfg.swayOutput}

    input "type:touchpad" {
      tap enabled
    }

    seat seat0 xcursor_theme ${config.khanelinix.desktop.addons.gtk.cursor.name} 24

    xwayland disable

    bindsym XF86MonBrightnessUp exec light -A 5
    bindsym XF86MonBrightnessDown exec light -U 5
    bindsym Print exec ${getExe pkgs.grim} /tmp/regreet.png
    bindsym Mod4+shift+e exec ${getExe' pkgs.sway "swaynag"} \
      -t warning \
      -m 'What do you want to do?' \
      -b 'Poweroff' 'systemctl poweroff' \
      -b 'Reboot' 'systemctl reboot'

    exec "${getExe pkgs.greetd.regreet} -l debug; ${getExe' pkgs.sway "swaymsg"} exit"
  '';
in
{
  options.khanelinix.display-managers.regreet = with types; {
    enable = mkBoolOpt false "Whether or not to enable greetd.";
    swayOutput = mkOpt lines "" "Sway Outputs config.";
  };

  config =
    mkIf cfg.enable
      {
        environment.systemPackages = [
          config.khanelinix.desktop.addons.gtk.cursor.pkg
          config.khanelinix.desktop.addons.gtk.icon.pkg
          config.khanelinix.desktop.addons.gtk.theme.pkg
          pkgs.vulkan-validation-layers
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

        services.greetd.settings.default_session = {
          command = "env GTK_USE_PORTAL=0 ${getExe pkgs.sway} --config ${greetdSwayConfig}";
        };

        security.pam.services.greetd = {
          enableGnomeKeyring = true;
          gnupg.enable = true;
        };
      };
}
