{
  options,
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.desktop.hyprland;
in {
  options.khanelinix.desktop.hyprland = with types; {
    enable = mkEnableOption "Hyprland.";
    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Extra configuration lines to add to `~/.config/hypr/hyprland.conf`.
      '';
    };
  };

  config =
    mkIf cfg.enable
    {
      # start swayidle as part of hyprland, not sway
      systemd.user.services.swayidle.Install.WantedBy = lib.mkForce ["hyprland-session.target"];

      wayland.windowManager.hyprland = {
        enable = true;
        xwayland.enable = true;
        systemdIntegration = true;

        settings = {
          input = {
            kb_layout = "us";
            follow_mouse = 1;

            touchpad = {
              natural_scroll = "no";
              disable_while_typing = true;
              tap-to-click = true;
            };

            sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
          };

          general = {
            gaps_in = 5;
            gaps_out = 20;
            border_size = 2;
            "col.inactive_border" = "rgb(5e6798)";
            "col.active_border" = "rgba(7793D1FF)";

            layout = "dwindle";
          };

          decoration = {
            rounding = 10;
            multisample_edges = true;

            active_opacity = 0.95;
            inactive_opacity = 0.9;
            fullscreen_opacity = 1.0;

            blur = "yes";
            blur_size = 5;
            blur_passes = 4;
            blur_new_optimizations = "on";

            drop_shadow = true;
            shadow_ignore_window = true;
            shadow_range = 20;
            shadow_render_power = 3;
            "col.shadow" = "0x55161925";
            "col.shadow_inactive" = "0x22161925";
          };

          animations = {
            enabled = "yes";

            # Some default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more
            bezier = [
              "myBezier, 0.05, 0.9, 0.1, 1.05"
              "overshot, 0.13, 0.99, 0.29, 1.1"
              "scurve, 0.98, 0.01, 0.02, 0.98"
              "easein, 0.47, 0, 0.745, 0.715"
            ];

            animation = [
              "windowsOut, 1, 7, default, popin 10%"
              "windows, 1, 5, overshot, popin 10%"
              "border, 1, 10, default"
              "fade, 1, 10, default"
              "workspaces, 1, 6, overshot, slide"
            ];
          };

          dwindle = {
            # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
            pseudotile = true; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
            preserve_split = true; # you probably want this
            force_split = 0;
          };

          master = {
            # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
            new_is_master = true;
          };

          gestures = {
            workspace_swipe = true;
            workspace_swipe_invert = false;
            workspace_swipe_fingers = 3;
          };

          "$mainMod" = "SUPER";
          "$LHYPER" = "SUPER_LALT_LCTRL"; # TODO: fix
          "$RHYPER" = "SUPER_RALT_RCTRL"; # TODO: fix

          # default applications
          "$term" = "kitty";
          "$browser" = "firefox-developer-edition";
          "$mail" = "thunderbird";
          "$editor" = "nvim";
          "$explorer" = "thunar";
          "$music" = "spotify";
          "$notepad" = "code - -profile notepad - -unity-launch ~/Templates";
          "$launcher" = "rofi - show drun - n";
          "$launcher_alt" = "rofi - show run - n";
          "$launchpad" = "rofi - show drun - config '~/.config/rofi/appmenu/rofi.rasi'";
          "$looking-glass" = "looking-glass-client";

          bind =
            [
              # ░█▀█░█▀█░█▀█░░░█░░░█▀█░█░█░█▀█░█▀▀░█░█░█▀▀░█▀▄░█▀▀
              # ░█▀█░█▀▀░█▀▀░░░█░░░█▀█░█░█░█░█░█░░░█▀█░█▀▀░█▀▄░▀▀█
              # ░▀░▀░▀░░░▀░░░░░▀▀▀░▀░▀░▀▀▀░▀░▀░▀▀▀░▀░▀░▀▀▀░▀░▀░▀▀▀
              "$mainMod, RETURN, exec, $term"
              "SUPER_SHIFT, RETURN, exec, $term --title floating_kitty --single-instance"
              "SUPER_ALT, T, exec, alacritty"
              "$mainMod, Q, killactive,"
              "SUPER_SHIFT, P, exec, hyprpicker -a && (convert -size 32x32 xc:$(wl-paste) /tmp/color.png && notify-send \"Color Code:\" \"$(wl-paste)\" -h \"string:bgcolor:$(wl-paste)\" --icon /tmp/color.png -u critical -t 4000)"
              "$mainMod, B, exec, $browser"
              "$mainMod, E, exec, $term ranger"
              "SUPER_SHIFT, E, exec, $explorer"
              "$mainMod, SPACE, exec, $launcher"
              "SUPER_SHIFT, SPACE, exec, $launcher_alt"
              "$mainMod, A, exec, $launchpad"
              "$mainMod, L, exec, swaylock --grace 0 --fade-in 0"
              "$mainMod, T, exec, $term btop"
              "$mainMod, N, exec, swaync-client -t -sw"
              # "SUPER, V, clipman pick -t rofi
              "$mainMod, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"
              "$mainMod, W, exec, $looking-glass"

              # ░█▀▀░█░█░█▀▀░▀█▀░█▀▀░█▄█
              # ░▀▀█░░█░░▀▀█░░█░░█▀▀░█░█
              # ░▀▀▀░░▀░░▀▀▀░░▀░░▀▀▀░▀░▀
              "$LHYPER, L, exec, systemctl --user exit"
              "$LHYPER, L, exit,    "
              # "$RHYPER, R, exec, reboot" # TODO: fix
              # "$RHYPER, P, exec, shutdown" # TODO: fix
              "$LHYPER, T, exec, notify-send 'test left'"
              "$RHYPER, T, exec, notify-send 'test right'"

              # ░█▀▀░█▀▀░█▀▄░█▀▀░█▀▀░█▀█░█▀▀░█░█░█▀█░▀█▀
              # ░▀▀█░█░░░█▀▄░█▀▀░█▀▀░█░█░▀▀█░█▀█░█░█░░█░
              # ░▀▀▀░▀▀▀░▀░▀░▀▀▀░▀▀▀░▀░▀░▀▀▀░▀░▀░▀▀▀░░▀░
              # Pictures
              ", Print, exec, file=\"$(xdg-user-dir PICTURES)/screenshots/$(date +'%Y%m%d_%H%M%S.png')\" && grim \"$file\" && notify-send --icon \"$file\" 'Screenshot Saved'"
              "SHIFT, Print, exec, file=\"$(xdg-user-dir PICTURES)/screenshots/$(date +'%Y%m%d_%H%M%S.png')\" && grim -g \"$(slurp)\" \"$file\" && notify-send --icon \"$file\" 'Screenshot Saved'"
              "SUPER_SHIFT, Print, exec, grim -g \"$(slurp)\" - | swappy -f -"
              "SUPER, Print, exec, grim - | swappy -f -"
              "CONTROL, Print, exec, grimblast copy screen && wl-paste -t image/png | convert png:- /tmp/clipboard.png && notify-send --icon=/tmp/clipboard.png 'Screen copied to clipboard'"
              "SUPER_CTRL, Print, exec, grimblast copy active && wl-paste -t image/png | convert png:- /tmp/clipboard.png && notify-send --icon=/tmp/clipboard.png 'Window copied to clipboard'"
              "SUPER_CTRL_SHIFT, Print, exec, grimblast copy area && wl-paste -t image/png | convert png:- /tmp/clipboard.png && notify-send --icon=/tmp/clipboard.png 'Area copied to clipboard'"
              # Screen recording
              "SUPER_CTRLALT, Print, exec, ~/.local/bin/record_screen screen                                                                                            "
              "SUPER_CTRLALTSHIFT, Print, exec, ~/.local/bin/record_screen area                                                                                          "

              # ░█░░░█▀█░█░█░█▀█░█░█░▀█▀
              # ░█░░░█▀█░░█░░█░█░█░█░░█░
              # ░▀▀▀░▀░▀░░▀░░▀▀▀░▀▀▀░░▀░
              "SUPER_ALT, V, togglefloating,"
              "$mainMod, P, pseudo, # dwindle"
              "$mainMod, J, togglesplit, # dwindle"
              "$mainMod, F, fullscreen"
              # "SUPER_SHIFT, V, workspaceopt, allfloat"

              # ░█░█░▀█▀░█▀█░█▀▄░█▀█░█░█
              # ░█▄█░░█░░█░█░█░█░█░█░█▄█
              # ░▀░▀░▀▀▀░▀░▀░▀▀░░▀▀▀░▀░▀
              # WINDOWS FOCUS
              "ALT,left,movefocus,l"
              "ALT,right,movefocus,r"
              "ALT,up,movefocus,u"
              "ALT,down,movefocus,d"
              # Move window
              "SUPER,left,movewindow,l"
              "SUPER,right,movewindow,r"
              "SUPER,up,movewindow,u"
              "SUPER,down,movewindow,d"

              # ░█░█░█▀█░█▀▄░█░█░█▀▀░█▀█░█▀█░█▀▀░█▀▀
              # ░█▄█░█░█░█▀▄░█▀▄░▀▀█░█▀▀░█▀█░█░░░█▀▀
              # ░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀▀░▀░░░▀░▀░▀▀▀░▀▀▀
              # Swipe through existing workspaces with CTRL_ALT + left / right
              "CTRL_ALT, right, workspace, +1"
              "CTRL_ALT, left, workspace, -1"

              # Move to workspace left/right
              "CTRL_ALT_SUPER, right, movetoworkspace, +1"
              "CTRL_ALT_SUPER, left, movetoworkspace, -1"

              # Scroll through existing workspaces with CTRL_ALT + scroll
              "CTRL_ALT, mouse_down, workspace, e+1"
              "CTRL_ALT, mouse_up, workspace, e-1"

              # MOVING silently LEFT/RIGHT
              "SUPER_SHIFT, right, movetoworkspacesilent, +1"
              "SUPER_SHIFT, left, movetoworkspacesilent, -1 "

              # Scratchpad
              "SUPER_ALT,grave,movetoworkspace,special"
              "SUPER,grave,togglespecialworkspace,"

              # ░█▄█░█▀█░█▀█░▀█▀░▀█▀░█▀█░█▀▄
              # ░█░█░█░█░█░█░░█░░░█░░█░█░█▀▄
              # ░▀░▀░▀▀▀░▀░▀░▀▀▀░░▀░░▀▀▀░▀░▀
              # simple movement between monitors
              "SUPER_CTRL, up, focusmonitor, u"
              "SUPER_CTRL, down, focusmonitor, d"
              "SUPER_CTRL, left, focusmonitor, l"
              "SUPER_CTRL, right, focusmonitor, r"

              # moving current workspace to monitor
              "SUPER_CTRL_SHIFT,down,movecurrentworkspacetomonitor,d"
              "SUPER_CTRL_SHIFT,up,movecurrentworkspacetomonitor,u"
              "SUPER_CTRL_SHIFT,left,movecurrentworkspacetomonitor,l"
              "SUPER_CTRL_SHIFT,right,movecurrentworkspacetomonitor,r"

              # ░█▄█░█▀▀░█▀▄░▀█▀░█▀█
              # ░█░█░█▀▀░█░█░░█░░█▀█
              # ░▀░▀░▀▀▀░▀▀░░▀▀▀░▀░▀
              ",XF86AudioRaiseVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 2.5%+"
              ",XF86AudioLowerVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 2.5%-"
              ",XF86AudioMute,exec,wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
              ",XF86MonBrightnessUp,exec,light -A 5"
              ",XF86MonBrightnessDown,exec,light -U 5"
              ",XF86AudioMedia,exec,playerctl play-pause"
              ",XF86AudioPlay,exec,playerctl play-pause"
              ",XF86AudioStop,exec,playerctl stop"
              ",XF86AudioPrev,exec,playerctl previous"
              ",XF86AudioNext,exec,playerctl next"
            ]
            # ░█░█░█▀█░█▀▄░█░█░█▀▀░█▀█░█▀█░█▀▀░█▀▀
            # ░█▄█░█░█░█▀▄░█▀▄░▀▀█░█▀▀░█▀█░█░░░█▀▀
            # ░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀▀░▀░░░▀░▀░▀▀▀░▀▀▀
            # Switch workspaces with CTRL_ALT + [0-9]
            ++ (builtins.concatLists (builtins.genList (
                x: let
                  ws = let
                    c = (x + 1) / 10;
                  in
                    builtins.toString (x + 1 - (c * 10));
                in [
                  "$CTRL_ALT, ${ws}, workspace, ${toString (x + 1)}"
                  "$CTRL_ALT, ${ws}, exec, $w${toString (x + 1)}"
                  "$CTRL_ALT_SUPER, ${ws}, movetoworkspace, ${toString (x + 1)}"
                  "$CTRL_ALT_SUPER, ${ws}, exec, $w${toString (x + 1)}"
                  "$SUPER_SHIFT, ${ws}, movetoworkspacesilent, ${toString (x + 1)}"
                ]
              )
              10));
          # Move/resize windows with mainMod + LMB/RMB and dragging
          bindm = [
            "$mainMod, mouse:272, movewindow #left click"
            "$mainMod, mouse:273, resizewindow #right click"
          ];

          windowrulev2 = [
            # ░█░█░▀█▀░█▀█░█▀▄░█▀█░█░█░░░█▀▄░█░█░█░░░█▀▀░█▀▀
            # ░█▄█░░█░░█░█░█░█░█░█░█▄█░░░█▀▄░█░█░█░░░█▀▀░▀▀█
            # ░▀░▀░▀▀▀░▀░▀░▀▀░░▀▀▀░▀░▀░░░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀▀▀
            # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more

            ##
            # ░█▀▀░█░░░█▀█░█▀█░▀█▀░▀█▀░█▀█░█▀▀
            # ░█▀▀░█░░░█░█░█▀█░░█░░░█░░█░█░█░█
            # ░▀░░░▀▀▀░▀▀▀░▀░▀░░▀░░▀▀▀░▀░▀░▀▀▀
            ##
            "float, class:Rofi"
            "float, class:viewnior"
            "float, class:feh"
            "float, class:wlogout"
            "float, class:file_progress"
            "float, class:confirm"
            "float, class:dialog"
            "float, class:download"
            "float, class:notification"
            "float, class:error"
            "float, class:splash"
            "float, class:confirmreset"
            "float, class:org.kde.polkit-kde-authentication-agent-1"
            "float, class:^(wdisplays)$"
            "size 1100 600, class:^(wdisplays)$"
            "float, class:^(blueman-manager)$"
            "float, class:^(nm-connection-editor)$"
            "float, title:^(floating_kitty)$"
            "size 1100 600, title:^(floating_kitty)$"
            "move center, title:^(floating_kitty)$"
            "animation slide, title:^(floating_kitty)$"
            "float, class:^(thunderbird)$,title:.*(Reminders)$"

            # Workspace 8 (VM) layout
            "size 1000 1330, class:^(virt-manager)$, title:^(Virtual Machine Manager)$"
            "float, class:^(virt-manager)$, title:^(Virtual Machine Manager)$"
            "move 80% 6%, class:^(virt-manager)$, title:^(Virtual Machine Manager)$"
            "float, class:^(looking-glass-client)$"
            "size 2360 1330, class:^(looking-glass-client)$"
            "move 25% 6%, class:^(looking-glass-client)$"
            "float,  class:^(virt-manager)$, title:^.*(on QEMU/KVM)$"
            "size 2360 1330, class:^(virt-manager)$, title:^.*(on QEMU/KVM)$"
            "move 25% 6%, class:^(virt-manager)$, title:^.*(on QEMU/KVM)$"

            # make Firefox PiP window floating and sticky
            "float, title:^(Picture-in-Picture)$"
            "pin, title:^(Picture-in-Picture)$"

            # fix xwayland apps
            "rounding 0, xwayland:1, floating:1"
            "center, class:^(.*jetbrains.*)$, title:^(Confirm Exit|Open Project|win424|win201|splash)$"
            "size 640 400, class:^(.*jetbrains.*)$, title:^(splash)$"

            ##
            # ░█▀█░█▀█░█▀█░█▀▀░▀█▀░▀█▀░█░█
            # ░█░█░█▀▀░█▀█░█░░░░█░░░█░░░█░
            # ░▀▀▀░▀░░░▀░▀░▀▀▀░▀▀▀░░▀░░░▀░
            ##
            "opaque, class:^(virt-manager)$,title:.*(on QEMU).*"
            "opaque, class:^(looking-glass-client)$"
            "opaque, title:^(.*(Twitch|TNTdrama|YouTube|Bally Sports|Video Entertainment|Plex)).*(Firefox).*$"
            "dimaround, class:^(gcr-prompter)$"

            # Require input
            "bordercolor rgba(ed8796FF), class:org.kde.polkit-kde-authentication-agent-1"
            "dimaround, class:org.kde.polkit-kde-authentication-agent-1"

            ##
            # ░▀█▀░█▀▄░█░░░█▀▀░▀█▀░█▀█░█░█░▀█▀░█▀▄░▀█▀░▀█▀
            # ░░█░░█░█░█░░░█▀▀░░█░░█░█░█▀█░░█░░█▀▄░░█░░░█░
            # ░▀▀▀░▀▀░░▀▀▀░▀▀▀░▀▀▀░▀░▀░▀░▀░▀▀▀░▀▀░░▀▀▀░░▀░
            ##
            "idleinhibit focus, class:^(steam_app).*"
            "idleinhibit focus, class:^(gamescope).*"
            "idleinhibit focus, class:.*(cemu|yuzu|ryujinx|emulationstation|retroarch).*"
            "idleinhibit fullscreen, title:.*(cemu|yuzu|ryujinx|emulationstation|retroarch).*"
            "idleinhibit fullscreen, title:^(.*(Twitch|TNTdrama|YouTube|Bally Sports|Video Entertainment|Plex)).*(Firefox).*$"
            "idleinhibit focus, title:^(.*(Twitch|TNTdrama|YouTube|Bally Sports|Video Entertainment|Plex)).*(Firefox).*$"
            "idleinhibit focus, class:^(mpv|.+exe)$"

            ##
            # ░█░█░█▀█░█▀▄░█░█░█▀▀░█▀█░█▀█░█▀▀░█▀▀░░░█▀▀░█▀█░█▀█░█▀▀░▀█▀░█▀▀
            # ░█▄█░█░█░█▀▄░█▀▄░▀▀█░█▀▀░█▀█░█░░░█▀▀░░░█░░░█░█░█░█░█▀▀░░█░░█░█
            # ░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀▀░▀░░░▀░▀░▀▀▀░▀▀▀░░░▀▀▀░▀▀▀░▀░▀░▀░░░▀▀▀░▀▀▀
            ##

            # Secondary Monitor Media
            "workspace 1, title:^(.*(Twitch|TNTdrama|YouTube|Bally Sports|Video Entertainment|Plex)).*(Firefox).*$" # TODO: Doesnt seem to work even though it says it matches
            #Browsers
            "workspace 2, title:^(?!.*(Twitch|TNTdrama|YouTube|Bally Sports|Video Entertainment|Plex)).*(Firefox).*$"
            "workspace special, title:^(.*(hidden tabs - Workona)).*(Firefox).*$" # TODO: Doesnt seem to work even though it says it matches
            # Code
            "workspace 3, class:^(Code)$"
            "workspace 3, class:^(neovide)$"
            "workspace 3, class:^(GitHub Desktop)$"
            "workspace 3, class:^(GitKraken)$"
            "workspace 3, class:^(kitty)$,title:^(nvim).*" # TODO: Doesnt seem to work even though it says it matches
            # Gaming
            "workspace 4 silent, class:^(Steam|steam)$"
            "workspace 4 silent, class:^(Steam|steam)., title:^(Steam|steam)$"
            "workspace 4 silent, class:^(gamescope)"
            "workspace 4, class:^(heroic)$"
            "workspace 4, class:^(lutris)$"
            "workspace 4, class:.*(cemu|yuzu|ryujinx|emulationstation|retroarch).*"
            "workspace 4, title:.*(cemu|yuzu|ryujinx|emulationstation|retroarch).*"
            # Messaging
            "workspace 5 silent, class:^(Slack)$"
            "workspace 5 silent, class:^(Caprine)$"
            "workspace 5 silent, class:^(org.telegram.desktop)$"
            "workspace 5 silent, class:^(discord)$"
            "workspace 5 silent, class:^(zoom)$"
            # Mail
            "workspace 6 silent, class:^(thunderbird)$"
            "workspace 6 silent, class:^(Mailspring)$"
            # Media
            "workspace 7, class:^(mpv)$"
            "workspace 7, class:^(vlc)$"
            "workspace 7 silent, class:^(Spotify)$"
            "tile, class:^(Spotify)$"
            "workspace 7 silent, class:^(elisa)$"
            #Remote
            "workspace 8 silent, class:^(virt-manager)$"
            "workspace 8 silent, class:^(gnome-connections)$"
            "workspace 8, class:^(looking-glass-client)$"
          ];

          exec-once = [
            # ░█▀█░█▀█░█▀█░░░█▀▀░▀█▀░█▀█░█▀▄░▀█▀░█░█░█▀█
            # ░█▀█░█▀▀░█▀▀░░░▀▀█░░█░░█▀█░█▀▄░░█░░█░█░█▀▀
            # ░▀░▀░▀░░░▀░░░░░▀▀▀░░▀░░▀░▀░▀░▀░░▀░░▀▀▀░▀░░

            # Startup background apps
            "${pkgs.libsForQt5.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1 & eval $(gnome-keyring-daemon -s --components=pkcs11,secrets,ssh,gpg) && export $(gnome-keyring-daemon --start --components=gpg,pkcs11,secrets,ssh)"
            "sleep 1"
            "command -v hyprpaper && hyprpaper"
            "command -v waybar && waybar"
            # "command -v eww && eww open bar && eww open secondary-bar"
            "command -v ckb-next && ckb-next -b"
            "command -v openrgb && openrgb --startminimized --profile default"
            "command -v 1password && 1password --silent"
            "command -v blueman-applet && blueman-applet"
            "command -v nm-applet && nm-applet --indicator"
            "command -v mpd && mpd"
            "command -v mpd-mpris && sleep 2 && mpd-mpris"
            "command -v clipman && wl-paste --watch clipman store"
            "command -v cliphist && wl-paste --type text --watch cliphist store" #Stores only text data
            "command -v cliphist && wl-paste --type image --watch cliphist store" #Stores only image data

            # Startup apps that have rules for organizing them
            "[workspace special silent ] kitty --session scratchpad" # Spawn scratchpad terminal
            "command -v firefox && firefox"
            "command -v steam && steam"
            "command -v discord && discord"
            "command -v thunderbird && thunderbird"

            "command -v virt-manager && virt-manager"
          ];

          exec = [
            "notify-send --icon ~/.face -u normal \"Hello $(whoami)\""
          ];
        };

        extraConfig = ''
          source=~/.config/hypr/displays.conf
          source=~/.config/hypr/polish.conf

          env = XDG_DATA_DIRS,'${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}':$XDG_DATA_DIRS

          ${cfg.extraConfig}
        '';
      };
    };
}
