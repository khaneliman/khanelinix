{
  config,
  lib,
  pkgs,

  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf mkEnableOption getExe;
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.programs.graphical.wms.hyprland;

  historicalLogAliases = builtins.listToAttrs (
    builtins.genList (x: {
      name = "hl${toString (x + 1)}";
      value = "cat $(ls -td $XDG_RUNTIME_DIR/hypr/*/ | sed -n '${toString (x + 2)}p')/hyprland.log 2>/dev/null || echo 'No historical log found at position ${toString (x + 1)}'";
    }) 4
  );

  historicalCrashAliases = builtins.listToAttrs (
    builtins.genList (x: {
      name = "hlc${toString (x + 1)}";
      value = "cat /home/${config.khanelinix.user.name}/.cache/hyprland/$(command ls -t /home/${config.khanelinix.user.name}/.cache/hyprland/ | grep 'hyprlandCrashReport' | head -n ${toString (x + 2)} | tail -n 1)";
    }) 4
  );
in
{
  options.khanelinix.programs.graphical.wms.hyprland = {
    enable = mkEnableOption "Hyprland";
    enableDebug = mkEnableOption "debug config";
    appendConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Extra configuration lines to add to bottom of `~/.config/hypr/hyprland.conf`.
      '';
    };
    prependConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Extra configuration lines to add to top of `~/.config/hypr/hyprland.conf`.
      '';
    };
  };

  imports = [
    ./apps.nix
    ./binds.nix
    ./permissions.nix
    ./variables.nix
    ./windowrules
    ./workspacerules.nix
  ];

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        grim
        hyprsunset
        hyprsysteminfo
        pkgs.khanelinix.record_screen
        slurp
        kdePackages.xwaylandvideobridge
      ];

      pointerCursor.hyprcursor = {
        enable = true;
      };

      sessionVariables = lib.mkIf (!(osConfig.programs.uwsm.enable or false)) (
        {
          CLUTTER_BACKEND = "wayland";
          MOZ_ENABLE_WAYLAND = "1";
          MOZ_USE_XINPUT2 = "1";
          # NOTE: causes gldriverquery crash on wayland
          # SDL_VIDEODRIVER = "wayland";
          WLR_DRM_NO_ATOMIC = "1";
          XDG_SESSION_TYPE = "wayland";
          _JAVA_AWT_WM_NONREPARENTING = "1";
          __GL_GSYNC_ALLOWED = "0";
          __GL_VRR_ALLOWED = "0";
        }
        // mkIf cfg.enableDebug {
          AQ_TRACE = "1";
          HYPRLAND_LOG_WLR = "1";
          HYPRLAND_TRACE = "1";
        }
      );

      shellAliases =
        {
          hl = "cat $XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log";
          hlc = "cat /home/${config.khanelinix.user.name}/.cache/hyprland/$(command ls -t /home/${config.khanelinix.user.name}/.cache/hyprland/ | grep 'hyprlandCrashReport' | head -n 1)";
          hlw = ''watch -n 0.1 "grep -v \"arranged\" $XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log | tail -n 40"'';
        }
        // historicalLogAliases
        // historicalCrashAliases;
    };

    khanelinix = {
      programs = {
        graphical = {
          launchers = {
            anyrun = enabled;
          };

          screenlockers = {
            hyprlock = enabled;
          };
        };
      };

      services = {
        hypridle = enabled;

        hyprpaper = {
          enable = true;
          enableSocketWatch = true;
        };

        hyprsunset = enabled;
      };

      suites = {
        wlroots = enabled;
      };

      theme = {
        gtk = enabled;
        qt = enabled;
      };
    };

    services.hyprpolkitagent = enabled;

    wayland.windowManager.hyprland =
      let
        systemctl = lib.getExe' pkgs.systemd "systemctl";
      in
      {
        enable = true;

        extraConfig =
          # bash
          ''
            ${cfg.prependConfig}

            ${cfg.appendConfig}
          '';

        package = lib.mkIf (osConfig ? programs.hyprland.package) osConfig.programs.hyprland.package;

        # ehhhhh
        # plugins = with pkgs.hyprlandPlugins; [
        #   hyprbars
        #   hyprexpo
        # ];

        settings = {
          exec = [ "${getExe pkgs.libnotify} --icon ~/.face -u normal \"Hello $(whoami)\"" ];

          plugin = {
            hyprbars =
              lib.mkIf (lib.elem pkgs.hyprlandPlugins.hyprbars config.wayland.windowManager.hyprland.plugins)
                {
                  bar_height = 20;
                  bar_precedence_over_border = true;

                  # order is right-to-left
                  hyprbars-button = [
                    # close
                    "rgb(ED8796), 15, , hyprctl dispatch killactive"
                    # maximize
                    "rgb(C6A0F6), 15, , hyprctl dispatch fullscreen 1"
                  ];
                };

            hyprexpo =
              lib.mkIf (lib.elem pkgs.hyprlandPlugins.hyprexpo config.wayland.windowManager.hyprland.plugins)
                {
                  columns = 3;
                  gap_size = 4;
                  bg_col = "rgb(000000)";
                };
          };
        };

        systemd = {
          enable = !(osConfig.programs.uwsm.enable or false);
          enableXdgAutostart = true;
          extraCommands = [
            "${systemctl} --user stop hyprland-session.target"
            "${systemctl} --user reset-failed"
            "${systemctl} --user start hyprland-session.target"
          ];

          variables = [
            "--all"
          ];
        };

        xwayland.enable = true;
      };
  };
}
