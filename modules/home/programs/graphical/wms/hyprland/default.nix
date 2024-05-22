{
  config,
  inputs,
  lib,
  pkgs,
  system,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption getExe;
  inherit (lib.internal) enabled;
  inherit (inputs) hyprland;

  cfg = config.khanelinix.programs.graphical.wms.hyprland;

  historicalLogAliases = builtins.listToAttrs (
    builtins.genList (x: {
      name = "hl${toString (x + 1)}";
      value = "cat /tmp/hypr/$(command ls -t /tmp/hypr/ | grep -v '\.lock$' | head -n ${toString (x + 2)} | tail -n 1)/hyprland.log";
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
      packages = with pkgs; [ xwaylandvideobridge ];

      sessionVariables = {
        CLUTTER_BACKEND = "wayland";
        GDK_BACKEND = "wayland,x11";
        HYPRLAND_LOG_WLR = "1";
        MOZ_ENABLE_WAYLAND = "1";
        MOZ_USE_XINPUT2 = "1";
        SDL_VIDEODRIVER = "wayland";
        WLR_DRM_NO_ATOMIC = "1";
        XDG_CURRENT_DESKTOP = "Hyprland";
        XDG_SESSION_DESKTOP = "Hyprland";
        XDG_SESSION_TYPE = "wayland";
        _JAVA_AWT_WM_NONREPARENTING = "1";
        __GL_GSYNC_ALLOWED = "0";
        __GL_VRR_ALLOWED = "0";
      };

      shellAliases = {
        hl = "cat $XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log";
        hlc = "cat /home/${config.khanelinix.user.name}/.local/cache/hyprland/$(command ls -t /home/${config.khanelinix.user.name}/.local/cache/hyprland/ | grep 'hyprlandCrashReport' | head -n 1)";
      } // historicalLogAliases // historicalCrashAliases;
    };

    khanelinix = {
      programs = {
        graphical = {
          apps = {
            partitionmanager = enabled;
          };

          launchers = {
            rofi = enabled;
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
      };

      suites = {
        wlroots = enabled;
      };

      theme = {
        gtk = enabled;
        qt = enabled;
      };
    };

    wayland.windowManager.hyprland = {
      enable = true;

      extraConfig = # bash
        ''
          ${cfg.prependConfig}

          env = HYPRLAND_TRACE,1

          ${cfg.appendConfig}
        '';

      package = hyprland.packages.${system}.hyprland;

      settings = {
        exec = [ "${getExe pkgs.libnotify} --icon ~/.face -u normal \"Hello $(whoami)\"" ];
      };

      systemd = {
        enable = true;
        variables = [ "--all" ];
      };

      xwayland.enable = true;
    };
  };
}
