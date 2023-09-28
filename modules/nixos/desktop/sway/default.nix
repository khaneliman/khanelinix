{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) types mkIf getExe getExe';
  inherit (lib.internal) mkBoolOpt mkOpt enabled fileWithText optionalString;
  inherit (config.khanelinix.desktop.addons) term;

  cfg = config.khanelinix.desktop.sway;
  substitutedConfig = pkgs.substituteAll {
    src = ./config;
    term = term.pkg.pname or term.pkg.name;
  };
in
{
  options.khanelinix.desktop.sway = with types; {
    enable = mkBoolOpt false "Whether or not to enable Sway.";
    extraConfig =
      mkOpt str "" "Additional configuration for the Sway config file.";
    wallpaper = mkOpt (nullOr package) null "The wallpaper to display.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.writeTextFile {
        name = "startsway";
        destination = "/bin/startsway";
        executable = true;
        text = ''
          #! ${getExe pkgs.bash}

          # Import environment variables from the login manager
          systemctl --user import-environment

          # Start Sway
          exec systemctl --user start sway.service
        '';
      })
    ];

    khanelinix = {
      desktop.addons = {
        foot = enabled;
        gtk = enabled;
        kanshi = enabled;
        mako = enabled;
        nautilus = enabled;
        wofi = enabled;
        xdg-portal = enabled;
      };

      home.configFile."sway/config".text = fileWithText substitutedConfig ''
        #############################
        #░░░░░░░░░░░░░░░░░░░░░░░░░░░#
        #░░█▀▀░█░█░█▀▀░▀█▀░█▀▀░█▄█░░#
        #░░▀▀█░░█░░▀▀█░░█░░█▀▀░█░█░░#
        #░░▀▀▀░░▀░░▀▀▀░░▀░░▀▀▀░▀░▀░░#
        #░░░░░░░░░░░░░░░░░░░░░░░░░░░#
        #############################

        # Launch services waiting for the systemd target sway-session.target
        exec "systemctl --user import-environment; systemctl --user start sway-session.target"

        # Start a user session dbus (required for things like starting
        # applications through wofi).
        exec dbus-daemon --session --address=unix:path=$XDG_RUNTIME_DIR/bus

        ${optionalString (cfg.wallpaper != null) ''
          output * {
            bg ${cfg.wallpaper.gnomeFilePath or cfg.wallpaper} fill
          }
        ''}

        ${cfg.extraConfig}
      '';

      security = {
        keyring = enabled;
        polkit = enabled;
      };

      suites = {
        wlroots = enabled;
      };

      display-managers = {
        gdm = {
          enable = true;
          defaultSession = "sway";
        };
      };
    };

    programs.sway = {
      enable = true;
      extraPackages = with pkgs; [
        sway-contrib.grimshot
        swaylock-fancy
        gnome.gnome-control-center
      ];

      extraSessionCommands = ''
        export SDL_VIDEODRIVER=wayland
        export QT_QPA_PLATFORM=wayland
        export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
        export _JAVA_AWT_WM_NONREPARENTING=1
        export MOZ_ENABLE_WAYLAND=1
        export XDG_SESSION_TYPE=wayland
        export XDG_SESSION_DESKTOP=sway
        export XDG_CURRENT_DESKTOP=sway
      '';
    };

    systemd.user = {
      targets.sway-session = {
        description = "Sway compositor session";
        documentation = [ "man:systemd.special(7)" ];
        bindsTo = [ "graphical-session.target" ];
        wants = [ "graphical-session-pre.target" ];
        after = [ "graphical-session-pre.target" ];
      };

      services.sway = {
        description = "Sway - Wayland window manager";
        documentation = [ "man:sway(5)" ];
        bindsTo = [ "graphical-session.target" ];
        wants = [ "graphical-session-pre.target" ];
        after = [ "graphical-session-pre.target" ];
        # We explicitly unset PATH here, as we want it to be set by
        # systemctl --user import-environment in startsway
        environment.PATH = lib.mkForce null;
        serviceConfig = {
          Type = "simple";
          ExecStart = ''
            ${getExe' pkgs.dbus "dbus-run-session"} ${getExe pkgs.sway} --debug
          '';
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
      };
    };
  };
}
