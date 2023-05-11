{ pkgs
, config
, types
, ...
}:
let
  cfg = config.khanelinix.desktop.hyprland.hypr;
in
{
  # Define an output to generate the final configuration file
  config = {
    khanelinix.home.configFile = {
      "hypr/apps.conf".source = pkgs.writeTextFile {
        name = "apps.conf";
        text = ''
          # ░█▀█░█▀█░█▀█░░░█▀▀░▀█▀░█▀█░█▀▄░▀█▀░█░█░█▀█
          # ░█▀█░█▀▀░█▀▀░░░▀▀█░░█░░█▀█░█▀▄░░█░░█░█░█▀▀
          # ░▀░▀░▀░░░▀░░░░░▀▀▀░░▀░░▀░▀░▀░▀░░▀░░▀▀▀░▀░░

          # Startup background apps
          exec-once = ~/.local/bin/xdg-desktop-portal.sh
          exec-once = ${pkgs.libsForQt5.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1 & eval $(gnome-keyring-daemon -s --components=pkcs11,secrets,ssh,gpg) && export $(gnome-keyring-daemon --start --components=gpg,pkcs11,secrets,ssh)
          exec-once = sleep 1
          exec-once = command -v hyprpaper && hyprpaper
          exec-once = command -v waybar && waybar
          exec-once = command -v swaync && swaync
          exec-once = command -v swayidle && swayidle -w
          exec-once = command -v ckb-next && ckb-next -b
          exec-once = command -v openrgb && openrgb --startminimized --profile default
          exec-once = command -v 1password && 1password --silent
          exec-once = command -v blueman-applet && blueman-applet
          exec-once = command -v nm-applet && nm-applet --indicator
          exec-once = command -v mpd && mpd
          exec-once = command -v mpd-mpris && sleep 2 && mpd-mpris
          exec-once = command -v clipman && wl-paste --watch clipman store
          exec-once = command -v cliphist && wl-paste --type text --watch cliphist store #Stores only text data
          exec-once = command -v cliphist && wl-paste --type image --watch cliphist store #Stores only image data

          # Startup apps that have rules for organizing them
          exec-once = [workspace special silent ] kitty --session scratchpad # Spawn scratchpad terminal
          exec-once = command -v firefox && firefox
          exec-once = command -v steam && steam
          exec-once = command -v thunderbird && thunderbird
          exec-once = command -v virt-manager && virt-manager
        '';
      };
    };
  };
}
