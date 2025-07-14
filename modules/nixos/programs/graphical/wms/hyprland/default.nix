{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib)
    concatStringsSep
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

        # package = pkgs.hyprland.override { debug = cfg.enableDebug; };
        # TODO: remove after next release
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
        configFile =
          {
            "hypr/assets/square.png".source = ./hypr/assets/square.png;
            "hypr/assets/diamond.png".source = ./hypr/assets/diamond.png;
          }
          // lib.optionalAttrs config.programs.hyprland.withUWSM {
            "uwsm/env-hyprland".text =
              ''
                export XDG_CURRENT_DESKTOP=Hyprland
                export XDG_SESSION_TYPE=wayland
                export XDG_SESSION_DESKTOP=Hyprland
                export HYPRCURSOR_THEME=${config.khanelinix.theme.cursor.name};
                export HYPRCURSOR_SIZE=${toString config.khanelinix.theme.cursor.size};
              ''
              + lib.optionalString cfg.enableDebug ''
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
              startscript = # bash
                ''
                  export PATH=$PATH:${programs}
                  export HYPRLAND_INSTANCE_SIGNATURE=$(command ls -t $XDG_RUNTIME_DIR/hypr | head -n 1)

                  hyprctl --batch '${
                    concatStringsSep " " [
                      "keyword animations:enabled 0;"
                      "keyword decoration:drop_shadow 0;"
                      "keyword decoration:blur:enabled 0;"
                      "keyword misc:vfr 0"
                    ]
                  }'

                  powerprofilesctl set performance
                  notify-send -a 'Gamemode' 'Optimizations activated' -u 'low'
                '';

              endscript = # bash
                ''
                  export PATH=$PATH:${programs}
                  export HYPRLAND_INSTANCE_SIGNATURE=$(command ls -t $XDG_RUNTIME_DIR/hypr | head -n 1)

                  hyprctl --batch '${
                    concatStringsSep " " [
                      "keyword animations:enabled 1;"
                      "keyword decoration:drop_shadow 1;"
                      "keyword decoration:blur:enabled 1;"
                      "keyword misc:vfr 1"
                    ]
                  }'

                  powerprofilesctl set balanced
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
