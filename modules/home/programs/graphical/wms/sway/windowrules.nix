{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.khanelinix.programs.graphical.wms.sway;
in
{
  config = mkIf cfg.enable {
    khanelinix.programs.graphical.wms.sway.settings = {
      # hide_edge_borders vertical
      # mouse_warping none
      # default_border pixel 1
      # default_floating_border pixel 1
      #
      # #set the variables
      # set {
      #  $float floating enable; border pixel 1; shadows enable
      # }

      # TODO: use sway's app_id for wayland and class for xwayland
      # use xlsclients to check which are x11
      # swaymsg -t get_tree for app_id/class/title
      assign = [
        ''[title="^(.*(Twitch|TNTdrama|YouTube|Bally Sports|Video Entertainment|Plex)).*(Firefox).*$"] "1"''
        ''[title="^(?!.*(Twitch|TNTdrama|YouTube|Bally Sports|Video Entertainment|Plex)).*(Firefox).*$"] "2"''
        # TODO: hide/minimize
        # ''[title="^(.*(hidden tabs - Workona)).*(Firefox).*$"] "2"''
        ''[app_id="^Code$"] "3"''
        ''[app_id="^neovide$"] "3"''
        ''[app_id="^GitHub Desktop$"] "3"''
        ''[app_id="^GitKraken$"] "3"''
        ''[class="[Ss]team$"] "4"''
        ''[title="[Ss]team$"] "4"''
        ''[class="^gamescope|steam_app.*$"] "4"''
        ''[app_id="^heroic$"] "4"''
        ''[app_id="^lutris$"] "4"''
        ''[app_id=".*(cemu|yuzu|Ryujinx|emulationstation|retroarch).*"] "4"''
        ''[title=".*(cemu|yuzu|Ryujinx|emulationstation|retroarch).*"] "4"''
        ''[app_id="^Slack$"] "5"''
        ''[class="[Cc]aprine$"] "5"''
        ''[app_id="^org.telegram.desktop$"] "5"''
        ''[app_id="^discord$"] "5"''
        ''[app_id="^vesktop$"] "5"''
        # ''[class="^zoom$"] "5"''
        ''[app_id="^Element$"] "5"''
        ''[app_id="^teams-for-linux$"] "5"''
        ''[app_id="^thunderbird$"] "6"''
        # ''[class="^Mailspring$"] "6"''
        ''[app_id="^mpv|vlc|VLC|mpdevil$"] "7"''
        ''[app_id="^Spotify$"] "7"''
        ''[title="^Spotify$"] "7"''
        ''[title="^Spotify Free$"] "7"''
        ''[class="^elisa$"] "7"''
        ''[class="^virt-manager|qemu$"] "8"''
        ''[class="^gnome-connections$"] "8"''
        ''[class="^looking-glass-client$"] "8"''
        ''[class="^selfservice$"] "8"''
        ''[class="^Wfica$"] "8"''
        ''[class="^Icasessionmgr$"] "8"''
      ];

      for_window = [
        # Float specific applications
        ''[class="Rofi"] floating enable''
        ''[class="viewnior"] floating enable''
        ''[class="feh"] floating enable''
        ''[class="wlogout"] floating enable''
        ''[class="file_progress"] floating enable''
        ''[class="confirm"] floating enable''
        ''[class="dialog"] floating enable''
        ''[class="download"] floating enable''
        ''[class="notification"] floating enable''
        ''[class="error"] floating enable''
        ''[class="splash"] floating enable''
        ''[class="confirmreset"] floating enable''
        ''[class="org.kde.polkit-kde-authentication-agent-1"] floating enable''
        ''[class="wdisplays"] floating enable''
        ''[class="blueman-manager"] floating enable''
        ''[class="nm-connection-editor"] floating enable''
        ''[title="^(floatterm)$"] floating enable''

        # TODO: convert rules
        # # Floating terminal
        # ''[title="floatterm"] floating enable; resize set 1100 600; move position center''
        #
        # # Calendar reminders
        # ''[class="thunderbird" title=".*(Reminders)"] floating enable; resize set 1100 600; move position 78% 6%; sticky enable''
        #
        # # Thunar file operation progress
        # ''[class="thunar" title="^(File Operation Progress)$"] floating enable; resize set 800 600; move position 78% 6%; sticky enable''
        #
        # # Workspace 8 (VM) layout
        # ''[class="virt-manager" title="^(Virtual Machine Manager)$"] floating enable; resize set 1000 1330; move position 80% 6%''
        # ''[class="looking-glass-client"] floating enable; resize set 2360 1330; move position 25% 6%''
        # ''[class="virt-manager" title=".*(on QEMU/KVM)$"] floating enable; resize set 2360 1330; move position 25% 6%''
        # ''[class="qemu"] floating enable; resize set 2360 1330; move position 25% 6%''
        #
        # # Make Firefox PiP window floating and sticky
        # ''[title="^(Picture-in-Picture)$"] floating enable; sticky enable''
        #
        # # Fix xwayland apps
        # ''[class=".*jetbrains.*" title="^(Confirm Exit|Open Project|win424|win201|splash)$"] floating enable; move position center''
        # ''[class=".*jetbrains.*" title="^(splash)$"] floating enable; resize set 640 400''
      ];
    };
  };
}
