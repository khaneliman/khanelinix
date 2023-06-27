{
  options,
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.display-managers.greetd;
  greetdSwayConfig = pkgs.writeText "greetd-sway-config" ''
    exec "dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP"
    input "type:touchpad" {
      tap enabled
    }
    seat seat0 xcursor_theme ${config.khanelinix.desktop.addons.gtk.cursor.name} 24

    xwayland disable

    bindsym XF86MonBrightnessUp exec light -A 5
    bindsym XF86MonBrightnessDown exec light -U 5
    bindsym Print exec ${lib.getExe pkgs.grim} /tmp/regreet.png
    bindsym Mod4+shift+e exec swaynag \
      -t warning \
      -m 'What do you want to do?' \
      -b 'Poweroff' 'systemctl poweroff' \
      -b 'Reboot' 'systemctl reboot'

    exec "${lib.getExe pkgs.greetd.regreet} -l debug; swaymsg exit"
  '';
in {
  options.khanelinix.display-managers.greetd = with types; {
    enable = mkBoolOpt false "Whether or not to enable greetd.";
  };

  config =
    mkIf cfg.enable
    {
      environment.systemPackages = [
        config.khanelinix.desktop.addons.gtk.cursor.pkg
        config.khanelinix.desktop.addons.gtk.theme.pkg
        config.khanelinix.desktop.addons.gtk.icon.pkg
      ];

      programs.regreet = {
        enable = true;
        settings = {
          background = {
            path = pkgs.khanelinix.wallpapers.flatppuccin_macchiato;
            fit = "Cover";
          };
          GTK = {
            cursor_theme_name = "${config.khanelinix.desktop.addons.gtk.cursor.name}";
            font_name = "${config.khanelinix.system.fonts.default} * 12";
            icon_theme_name = "${config.khanelinix.desktop.addons.gtk.icon.name}";
            theme_name = "${config.khanelinix.desktop.addons.gtk.theme.name}";
          };
        };
      };

      services.greetd.settings.default_session.command = "${pkgs.sway}/bin/sway --config ${greetdSwayConfig}";

      security.pam.services.greetd.gnupg.enable = true;
      security.pam.services.greetd.enableGnomeKeyring = true;
    };
}
