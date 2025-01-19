{
  config,
  khanelinix-lib,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption getExe;
  inherit (khanelinix-lib) enabled;

  cfg = config.khanelinix.programs.graphical.wms.hyprland;

  historicalLogAliases = builtins.listToAttrs (
    builtins.genList (x: {
      name = "hl${toString (x + 1)}";
      value = "cat /tmp/hypr/$(command ls -t /tmp/hypr/ | grep -v '\.lock$' | head -n ${toString (x + 2)} | tail -n 1)/hyprland${lib.optionalString cfg.enableDebug "d"}.log";
    }) 4
  );

  historicalCrashAliases = builtins.listToAttrs (
    builtins.genList (x: {
      name = "hlc${toString (x + 1)}";
      value = "cat /home/${config.khanelinix.user.name}/.local/cache/hyprland/$(command ls -t /home/${config.khanelinix.user.name}/.local/cache/hyprland/ | grep 'hyprlandCrashReport' | head -n ${toString (x + 2)} | tail -n 1)";
    }) 4
  );
in
{
  options.khanelinix.programs.graphical.wms.hyprland = {
    enable = mkEnableOption "Hyprland.";
    enableDebug = mkEnableOption "Enable debug mode.";
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

  imports = lib.snowfall.fs.get-non-default-nix-files ./.;

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        xwaylandvideobridge
        # NOTE: xdph requirement
        grim
        slurp
        hyprsunset
        hyprsysteminfo
      ];

      sessionVariables = lib.mkIf (!osConfig.programs.uwsm.enable) (
        {
          CLUTTER_BACKEND = "wayland";
          GDK_BACKEND = "wayland,x11";
          HYPRCURSOR_THEME = config.khanelinix.theme.gtk.cursor.name;
          HYPRCURSOR_SIZE = "${toString config.khanelinix.theme.cursor.size}";
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
          hl = "cat $XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland${lib.optionalString cfg.enableDebug "d"}.log";
          hlc = "cat /home/${config.khanelinix.user.name}/.local/cache/hyprland/$(command ls -t /home/${config.khanelinix.user.name}/.local/cache/hyprland/ | grep 'hyprlandCrashReport' | head -n 1)";
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
        cliphist.systemdTargets = [ "hyprland-session.target" ];

        hypridle = enabled;

        hyprpaper = {
          enable = true;
          enableSocketWatch = true;
        };
      };

      suites = {
        wlroots = enabled;
      };

      theme = {
        gtk = enabled;
        qt = enabled;
      };
    };

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

        package = pkgs.hyprland.override { debug = cfg.enableDebug; };

        settings = {
          exec = [ "${getExe pkgs.libnotify} --icon ~/.face -u normal \"Hello $(whoami)\"" ];
        };

        # systemd = lib.mkIf (!osConfig.programs.uwsm.enable) {
        systemd = {
          enable = !osConfig.programs.uwsm.enable;
          enableXdgAutostart = true;
          extraCommands = [
            "${systemctl} --user stop hyprland-session.target"
            "${systemctl} --user reset-failed"
            "${systemctl} --user start hyprland-session.target"
            "${systemctl} --user start hyprpolkitagent"
          ];

          variables = [
            "--all"
          ];
        };

        xwayland.enable = true;
      };
  };
}
