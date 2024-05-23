{
  config,
  inputs,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    getExe
    getExe'
    ;
  inherit (lib.${namespace})
    mkBoolOpt
    mkOpt
    enabled
    fileWithText
    optionalString
    ;
  inherit (config.${namespace}.desktop.addons) term;
  inherit (inputs) nixpkgs-wayland;

  cfg = config.${namespace}.programs.graphical.wms.sway;
  substitutedConfig = pkgs.substituteAll {
    src = ./config;
    term = term.pkg.pname or term.pkg.name;
  };
in
{
  options.${namespace}.programs.graphical.wms.sway = with types; {
    enable = mkBoolOpt false "Whether or not to enable Sway.";
    extraConfig = mkOpt str "" "Additional configuration for the Sway config file.";
    wallpaper = mkOpt (nullOr package) null "The wallpaper to display.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.writeTextFile {
        name = "startsway";
        destination = "/bin/startsway";
        executable = true;
        text = # bash
          ''
            #! ${getExe pkgs.bash}

            # Import environment variables from the login manager
            systemctl --user import-environment

            # Start Sway
            exec systemctl --user start sway.service
          '';
      })
      pkgs.brightnessctl
      pkgs.playerctl
    ];

    khanelinix = {
      display-managers = {
        gdm = {
          enable = true;
          defaultSession = "sway";
        };
      };

      programs = {
        graphical = {
          addons = {
            # TODO: moved to home-manager
            # kanshi = enabled;
            keyring = enabled;
            # TODO: moved to home-manager
            # mako = enabled;
            # TODO: moved to home-manager
            # wofi = enabled;
            xdg-portal = enabled;
          };

          file-managers = {
            nautilus = enabled;
          };
        };

        # TODO: moved to home-manager
        # terminal = {
        #   emulators = {
        #     foot = enabled;
        #   };
        # };
      };

      home.configFile."sway/config".text =
        fileWithText substitutedConfig # bash
          ''
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

      theme = {
        gtk = enabled;
        qt = enabled;
      };
    };

    programs.sway = {
      enable = true;
      package = nixpkgs-wayland.sway;

      extraPackages = with pkgs; [
        sway-contrib.grimshot
        swaylock-fancy
        gnome.gnome-control-center
      ];

      extraSessionCommands = # bash
        ''
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
          ExecStart = # bash
            ''
              ${getExe' pkgs.dbus "dbus-run-session"} ${getExe config.programs.sway.package} --debug
            '';
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
      };
    };
  };
}
