{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    makeBinPath
    mkIf
    types
    ;
  inherit (lib.khanelinix) mkOpt enabled;

  cfg = config.khanelinix.programs.graphical.wms.hyprland;

  programs = makeBinPath (
    with pkgs;
    [
      config.programs.hyprland.package
      coreutils
      config.services.power-profiles-daemon.package
      systemd
      libnotify
      kitty
      gawk
      procps
      util-linux
      swaynotificationcenter
      findutils
    ]
  );
in
{
  options.khanelinix.programs.graphical.wms.hyprland = with types; {
    enable = lib.mkEnableOption "Hyprland";
    enableDebug = lib.mkEnableOption "debug mode";
    customConfigFiles =
      mkOpt attrs { }
        "Custom configuration files that can be used to override the default files.";
    customFiles = mkOpt attrs { } "Custom files that can be used to override the default files.";
    wallpaper = mkOpt (nullOr package) null "The wallpaper to display.";
  };

  config = mkIf cfg.enable {
    environment = {
      sessionVariables = lib.mkIf (!config.programs.uwsm.enable) {
        HYPRCURSOR_THEME = config.khanelinix.theme.cursor.name;
        HYPRCURSOR_SIZE = "${toString config.khanelinix.theme.cursor.size}";
      };
    };

    programs = {
      hyprland = {
        enable = true;
        withUWSM = true;

        package = pkgs.hyprland.override { debug = cfg.enableDebug; };
      };
    };

    khanelinix = {
      display-managers = {
        sddm = {
          enable = true;
        };
      };

      home = {
        configFile = {
          "hypr/assets/square.png".source = ./hypr/assets/square.png;
          "hypr/assets/diamond.png".source = ./hypr/assets/diamond.png;
        }
        // lib.optionalAttrs config.programs.hyprland.withUWSM {
          "uwsm/env-hyprland".text =
            /* Bash */ ''
              export XDG_CURRENT_DESKTOP=Hyprland
              export XDG_SESSION_TYPE=wayland
              export XDG_SESSION_DESKTOP=Hyprland
              export HYPRCURSOR_THEME=${config.khanelinix.theme.cursor.name};
              export HYPRCURSOR_SIZE=${toString config.khanelinix.theme.cursor.size};
            ''
            + lib.optionalString cfg.enableDebug /* Bash */ ''
              export AQ_TRACE=1;
              export HYPRLAND_LOG_WLR=1;
              export HYPRLAND_TRACE=1;
            '';
        }
        // cfg.customConfigFiles;

        file = { } // cfg.customFiles;
      };

      programs = {
        graphical = {
          apps = {
            gnome-disks = enabled;
            partitionmanager = enabled;
          };

          addons = {
            gamemode = {
              startscript = /* bash */ ''
                export PATH=$PATH:${programs}
                export HYPRLAND_INSTANCE_SIGNATURE=$(command ls -t $XDG_RUNTIME_DIR/hypr | head -n 1)

                LOG_FILE="$XDG_RUNTIME_DIR/gamemode-start.log"
                echo "=== Gamemode Start: $(date) ===" > "$LOG_FILE"

                hyprctl --batch '${
                  lib.concatStringsSep " " [
                    "keyword animations:enabled 0;"
                    "keyword decoration:shadow:enabled 0;"
                    "keyword decoration:blur:enabled 0;"
                    "keyword decoration:active_opacity 1.0;"
                    "keyword decoration:inactive_opacity 1.0;"
                    "keyword decoration:fullscreen_opacity 1.0;"
                    "keyword misc:vfr 0;"
                    "keyword misc:vrr 0"
                  ]
                }'

                echo "Setting kitty opacity to 1.0..." >> "$LOG_FILE"
                for socket in $XDG_RUNTIME_DIR/kitty-*; do
                  [ -S "$socket" ] && kitten @ --to unix:"$socket" set-background-opacity 1.0 2>&1 | tee -a "$LOG_FILE"
                done

                echo "Enabling Do Not Disturb..." >> "$LOG_FILE"
                swaync-client -dn 2>&1 | tee -a "$LOG_FILE" || echo "✗ swaync-client failed" >> "$LOG_FILE"

                # echo "Hiding waybar..." >> "$LOG_FILE"
                # pkill -SIGUSR1 waybar 2>&1 | tee -a "$LOG_FILE" || echo "✗ waybar toggle failed" >> "$LOG_FILE"

                echo "Setting AMD GPU to high performance..." >> "$LOG_FILE"
                echo high | tee /sys/class/drm/card*/device/power_dpm_force_performance_level 2>&1 | tee -a "$LOG_FILE" || echo "✗ GPU performance mode failed" >> "$LOG_FILE"

                {
                  GAME_PIDS=$(pgrep -af 'steam_.*game|proton|wine-preloader|wine64-preloader|lutris|heroic|gamemoderun' | awk '{print $1}')
                  if [ -n "$GAME_PIDS" ]; then
                    echo "$GAME_PIDS" | xargs -r renice -n -10 -p
                    echo "Boosted priority for PIDs: $GAME_PIDS" >> "$LOG_FILE"
                  else
                    echo "No game processes found to boost" >> "$LOG_FILE"
                  fi
                } 2>&1 | tee -a "$LOG_FILE" || true

                # Set power profile to performance (may fail if not supported)
                echo "Setting power profile to performance..." >> "$LOG_FILE"
                powerprofilesctl set performance 2>&1 | tee -a "$LOG_FILE" || echo "✗ Performance mode not supported" >> "$LOG_FILE"
                echo "=== Gamemode Start Complete ===" >> "$LOG_FILE"
                notify-send -a 'Gamemode' 'Optimizations activated' -u 'low'
              '';

              endscript = /* bash */ ''
                export PATH=$PATH:${programs}
                export HYPRLAND_INSTANCE_SIGNATURE=$(command ls -t $XDG_RUNTIME_DIR/hypr | head -n 1)

                LOG_FILE="$XDG_RUNTIME_DIR/gamemode-end.log"
                echo "=== Gamemode End: $(date) ===" > "$LOG_FILE"

                hyprctl --batch '${
                  lib.concatStringsSep " " [
                    "keyword animations:enabled 1;"
                    "keyword decoration:shadow:enabled 1;"
                    "keyword decoration:blur:enabled 1;"
                    "keyword decoration:active_opacity 0.95;"
                    "keyword decoration:inactive_opacity 0.9;"
                    "keyword decoration:fullscreen_opacity 1.0;"
                    "keyword misc:vfr 1;"
                    "keyword misc:vrr 2"
                  ]
                }'

                echo "Restoring kitty opacity to 0.90..." >> "$LOG_FILE"
                for socket in $XDG_RUNTIME_DIR/kitty-*; do
                  [ -S "$socket" ] && kitten @ --to unix:"$socket" set-background-opacity 0.90 2>&1 | tee -a "$LOG_FILE"
                done

                echo "Disabling Do Not Disturb..." >> "$LOG_FILE"
                swaync-client -df 2>&1 | tee -a "$LOG_FILE" || echo "✗ swaync-client restore failed" >> "$LOG_FILE"

                # echo "Showing waybar..." >> "$LOG_FILE"
                # pkill -SIGUSR1 waybar 2>&1 | tee -a "$LOG_FILE" || echo "✗ waybar restore failed" >> "$LOG_FILE"

                echo "Restoring AMD GPU to auto mode..." >> "$LOG_FILE"
                echo auto | tee /sys/class/drm/card*/device/power_dpm_force_performance_level 2>&1 | tee -a "$LOG_FILE" || echo "✗ GPU auto mode restore failed" >> "$LOG_FILE"

                {
                  GAME_PIDS=$(pgrep -af 'steam_.*game|proton|wine-preloader|wine64-preloader|lutris|heroic|gamemoderun' | awk '{print $1}')
                  if [ -n "$GAME_PIDS" ]; then
                    echo "$GAME_PIDS" | xargs -r renice -n 0 -p
                    echo "Restored priority for PIDs: $GAME_PIDS" >> "$LOG_FILE"
                  else
                    echo "No game processes found to restore" >> "$LOG_FILE"
                  fi
                } 2>&1 | tee -a "$LOG_FILE" || true

                echo "Restoring power profile to balanced..." >> "$LOG_FILE"
                powerprofilesctl set balanced 2>&1 | tee -a "$LOG_FILE" || echo "✗ Power profile restore failed" >> "$LOG_FILE"
                echo "=== Gamemode End Complete ===" >> "$LOG_FILE"
                notify-send -a 'Gamemode' 'Optimizations deactivated' -u 'low'
              '';
            };
          };

          file-managers = {
            nautilus = enabled;
          };
        };
      };

      security = {
        keyring = enabled;
        polkit = enabled;
      };

      suites = {
        wlroots = enabled;
      };

      theme = {
        gtk = enabled;
        qt = enabled;
      };
    };
  };
}
