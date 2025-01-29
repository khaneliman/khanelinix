{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    makeBinPath
    mkIf
    types
    ;
  inherit (lib.${namespace}) mkBoolOpt mkOpt enabled;

  cfg = config.${namespace}.programs.graphical.wms.hyprland;

  programs = makeBinPath (
    with pkgs;
    [
      # TODO: make sure this references same package as home-manager
      hyprland
      coreutils
      config.services.power-profiles-daemon.package
      systemd
      libnotify
    ]
  );
in
{
  options.${namespace}.programs.graphical.wms.hyprland = with types; {
    enable = mkBoolOpt false "Whether or not to enable Hyprland.";
    customConfigFiles =
      mkOpt attrs { }
        "Custom configuration files that can be used to override the default files.";
    customFiles = mkOpt attrs { } "Custom files that can be used to override the default files.";
    wallpaper = mkOpt (nullOr package) null "The wallpaper to display.";
  };

  config = mkIf cfg.enable {
    environment = {
      sessionVariables = lib.mkIf (!config.programs.uwsm.enable) {
        HYPRCURSOR_THEME = config.${namespace}.theme.cursor.name;
        HYPRCURSOR_SIZE = "${toString config.${namespace}.theme.cursor.size}";
      };
    };

    programs = {
      hyprland = {
        enable = true;
        withUWSM = true;
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
            "uwsm/env-hyprland".text = ''
              export XDG_CURRENT_DESKTOP=Hyprland
              export XDG_SESSION_TYPE=wayland
              export XDG_SESSION_DESKTOP=Hyprland
              export HYPRCURSOR_THEME=${config.${namespace}.theme.cursor.name};
              export HYPRCURSOR_SIZE=${toString config.${namespace}.theme.cursor.size};
            '';
          }
          // cfg.customConfigFiles;

        file = { } // cfg.customFiles;
      };

      programs = {
        graphical = {
          apps = {
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
            thunar = enabled;
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
