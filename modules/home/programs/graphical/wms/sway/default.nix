{
  config,
  lib,
  pkgs,

  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.programs.graphical.wms.sway;

in
{
  options.khanelinix.programs.graphical.wms.sway = {
    enable = mkEnableOption "sway";
    enableDebug = mkEnableOption "debug mode";
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

  imports = [
    ./apps.nix
    ./binds.nix
    ./windowrules.nix
  ];

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        grim
        grimblast
        hyprpicker
        # NOTE: removed from nixpkgs
        # kdePackages.xwaylandvideobridge
        khanelinix.record_screen
        libnotify
        networkmanagerapplet
        playerctl
        slurp
        smile
        swappy
        wayvnc
      ];

      sessionVariables = lib.mkIf (!(osConfig.khanelinix.programs.graphical.wms.sway.withUWSM or false)) {
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
      };
    };

    khanelinix = {
      programs = {
        graphical = {
          launchers = {
            anyrun = enabled;
            vicinae = enabled;
          };

          screenlockers = {
            swaylock = enabled;
          };
        };
      };

      services = {
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
      package = lib.mkIf (osConfig ? programs.sway.package) osConfig.programs.sway.package;
      checkConfig = false;

      config = {
        bars = [ ];

        floating = {
          modifier = "Shift";
        };

        gaps = {
          inner = 5;
          outer = 20;
        };

        input = {
          "*" = {
            xkb_layout = "us";
            xkb_numlock = "enabled";
            # repeat_delay = 0;
            # repeat_rate = 50;
          };
        };

        modifier = "Mod4";

        terminal = "kitty";

        workspaceAutoBackAndForth = true;
        workspaceLayout = "default";
      }
      // cfg.settings;

      extraConfig = ''
        blur enable
        blur_passes 4
        blur_radius 5

        shadows enable
        shadows_on_csd enable
        titlebar_separator disable
        scratchpad_minimize disable

        ${cfg.appendConfig}
      '';

      extraConfigEarly = cfg.prependConfig;
      inherit (cfg) extraSessionCommands;

      systemd = {
        enable = !(osConfig.khanelinix.programs.graphical.wms.sway.withUWSM or false);
        xdgAutostart = true;

        variables = [
          "--all"
        ];
      };

      xwayland = true;
    };
  };
}

# TODO: get what we can into sway
# decoration = {
#   active_opacity = 0.95;
#   fullscreen_opacity = 1.0;
#   inactive_opacity = 0.9;
#   rounding = 10;
#
#   drop_shadow = true;
#   shadow_ignore_window = true;
#   shadow_range = 20;
#   shadow_render_power = 3;
#   "col.shadow" = "0x55161925";
#   "col.shadow_inactive" = "0x22161925";
# };
#
# dwindle = {
#   # See https://wiki.sway.org/Configuring/Dwindle-Layout/ for more
#   # force_split = 0;
#   preserve_split = true; # you probably want this
#   pseudotile = false; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
#   no_gaps_when_only = false;
#   special_scale_factor = 0.9;
# };
#
# general = {
#   # allow_tearing = true;
#   border_size = 2;
#   "col.active_border" = "rgba(7793D1FF)";
#   "col.inactive_border" = "rgb(5e6798)";
#   gaps_in = 5;
#   gaps_out = 20;
#   layout = "dwindle";
# };
#
# group = {
#   # new windows in a group spawn after current or at group tail
#   insert_after_current = true;
#   # focus on the window that has just been moved out of the group
#   focus_removed_window = true;
#
#   "col.border_active" = "rgba(88888888)";
#   "col.border_inactive" = "rgba(00000088)";
#
#   groupbar = {
#     # groupbar stuff
#     # this removes the ugly gradient around grouped windows - which sucks
#     gradients = false;
#     font_size = 14;
#
#     # titles look ugly, and I usually know what I'm looking at
#     render_titles = false;
#
#     # scrolling in the groupbar changes group active window
#     scrolling = true;
#   };
# };
