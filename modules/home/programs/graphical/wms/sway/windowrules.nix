{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.${namespace}.programs.graphical.wms.sway;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.sway = {
      config = {
        # hide_edge_borders vertical
        # mouse_warping none
        # default_border pixel 1
        # default_floating_border pixel 1
        #
        # #set the variables
        # set {
        #  $float floating enable; border pixel 1; shadows enable
        # }

        assigns = {
          "1: web" = [
            { title = "^(.*(Twitch|TNTdrama|YouTube|Bally Sports|Video Entertainment|Plex)).*(Firefox).*$"; }
          ];
          "2: browsers" = [
            { title = "^(?!.*(Twitch|TNTdrama|YouTube|Bally Sports|Video Entertainment|Plex)).*(Firefox).*$"; }
            # TODO: hide/minimize
            # { title = "^(.*(hidden tabs - Workona)).*(Firefox).*$"; }
          ];
          "3: code" = [
            { class = "^Code$"; }
            { class = "^neovide$"; }
            { class = "^GitHub Desktop$"; }
            { class = "^GitKraken$"; }
          ];
          "4: gaming" = [
            { class = "^Steam|steam$"; }
            {
              class = "^Steam|steam$";
              title = "^Steam|steam$";
            }
            { class = "^gamescope|steam_app.*$"; }
            { class = "^heroic$"; }
            { class = "^lutris$"; }
            { class = ".*(cemu|yuzu|Ryujinx|emulationstation|retroarch).*"; }
            { title = ".*(cemu|yuzu|Ryujinx|emulationstation|retroarch).*"; }
          ];
          "5: messaging" = [
            { class = "^Slack$"; }
            { class = "^Caprine$"; }
            { class = "^org.telegram.desktop$"; }
            { class = "^discord$"; }
            { class = "^zoom$"; }
            { class = "^Element$"; }
            { class = "^teams-for-linux$"; }
          ];
          "6: mail" = [
            { class = "^thunderbird$"; }
            { class = "^Mailspring$"; }
          ];
          "7: media" = [
            { class = "^mpv|vlc|mpdevil$"; }
            { class = "^Spotify$"; }
            { title = "^Spotify$"; }
            { title = "^Spotify Free$"; }
            {
              class = "^Spotify$";
              floating = true;
            }
            {
              class = "^Spotify Free$";
              floating = true;
            }
            { class = "^elisa$"; }
          ];
          "8: remote" = [
            { class = "^virt-manager|qemu$"; }
            { class = "^gnome-connections$"; }
            { class = "^looking-glass-client$"; }
          ];
        };

        floating = {
          criteria = [
            # Float specific applications
            { class = "Rofi"; }
            { class = "viewnior"; }
            { class = "feh"; }
            { class = "wlogout"; }
            { class = "file_progress"; }
            { class = "confirm"; }
            { class = "dialog"; }
            { class = "download"; }
            { class = "notification"; }
            { class = "error"; }
            { class = "splash"; }
            { class = "confirmreset"; }
            { class = "org.kde.polkit-kde-authentication-agent-1"; }
            { class = "wdisplays"; }
            { class = "blueman-manager"; }
            { class = "nm-connection-editor"; }
            { title = "^(floatterm)$"; }
          ];

          # # Floating terminal
          # [title="floatterm"] $float; resize set 1100 600; move position center; animation none
          #
          # # Calendar reminders
          # [class="thunderbird" title=".*(Reminders)"] $float; resize set 1100 600; move position 78% 6%; sticky enable
          #
          # # Thunar file operation progress
          # [class="thunar" title="^(File Operation Progress)$"] $float; resize set 800 600; move position 78% 6%; sticky enable
          #
          # # Workspace 8 (VM) layout
          # [class="virt-manager" title="^(Virtual Machine Manager)$"] $float; resize set 1000 1330; move position 80% 6%
          # [class="looking-glass-client"] $float; resize set 2360 1330; move position 25% 6%
          # [class="virt-manager" title=".*(on QEMU/KVM)$"] $float; resize set 2360 1330; move position 25% 6%
          # [class="qemu"] $float; resize set 2360 1330; move position 25% 6%
          #
          # # Make Firefox PiP window floating and sticky
          # [title="^(Picture-in-Picture)$"] $float; sticky enable
          #
          # # Fix xwayland apps
          # [class=".*jetbrains.*" title="^(Confirm Exit|Open Project|win424|win201|splash)$"] $float; move position center
          # [class=".*jetbrains.*" title="^(splash)$"] $float; resize set 640 400
        };
      };
    };
  };
}
