{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.programs.graphical.wms.sway;

in
{
  options.${namespace}.programs.graphical.wms.sway = {
    enable = mkEnableOption "sway.";
    enableDebug = mkEnableOption "Enable debug mode.";
    appendConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Extra configuration lines to add to bottom of `~/.config/hypr/sway.conf`.
      '';
    };
    prependConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Extra configuration lines to add to top of `~/.config/hypr/sway.conf`.
      '';
    };
    extraSessionCommands = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Extra shell commands to run at start of session.
      '';
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = ''
        Configuration to pass through to the main sway module.
      '';
    };
  };

  # imports = lib.snowfall.fs.get-non-default-nix-files ./.;
  imports = [
    ./apps.nix
    ./binds.nix
    ./variables.nix
  ];

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [ xwaylandvideobridge ];

      sessionVariables = {
        CLUTTER_BACKEND = "wayland";
        GDK_BACKEND = "wayland,x11";
        MOZ_ENABLE_WAYLAND = "1";
        MOZ_USE_XINPUT2 = "1";
        SDL_VIDEODRIVER = "wayland";
        WLR_DRM_NO_ATOMIC = "1";
        XDG_CURRENT_DESKTOP = "sway";
        XDG_SESSION_DESKTOP = "sway";
        XDG_SESSION_TYPE = "wayland";
        _JAVA_AWT_WM_NONREPARENTING = "1";
        __GL_GSYNC_ALLOWED = "0";
        __GL_VRR_ALLOWED = "0";
      };
    };

    khanelinix = {
      programs = {
        graphical = {
          launchers = {
            anyrun = enabled;
          };

          screenlockers = {
            swaylock = enabled;
          };
        };
      };

      services = {
        cliphist.systemdTargets = [ "sway-session.target" ];

        swayidle = enabled;
      };

      suites = {
        wlroots = enabled;
      };

      theme = {
        gtk = enabled;
        qt = enabled;
      };
    };

    wayland.windowManager.sway = {
      enable = true;
      package = pkgs.sway;

      config = {
        modifier = "Mod4";

        # terminal = "wezterm";

        bars = [ ];

        gaps = {
          inner = 5;
          outer = 20;
        };

      } // cfg.settings;

      extraConfig = cfg.appendConfig;
      extraConfigEarly = cfg.prependConfig;
      inherit (cfg) extraSessionCommands;

      systemd = {
        enable = true;
        xdgAutostart = true;

        variables = [ "--all" ];
      };

      xwayland = true;
    };
  };
}
