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
  inherit (pkgs.stdenv.hostPlatform) isLinux;

  cfg = config.khanelinix.programs.graphical.wms.hyprland;
  useSystemHyprland = osConfig ? programs.hyprland.enable && osConfig.programs.hyprland.enable;
  luaLspPackage =
    if useSystemHyprland then
      osConfig.programs.hyprland.package
    else
      config.wayland.windowManager.hyprland.package;

  historicalLogAliases = builtins.listToAttrs (
    builtins.genList (x: {
      name = "hl${toString (x + 1)}";
      value = "cat $(ls -td $XDG_RUNTIME_DIR/hypr/*/ | sed -n '${toString (x + 2)}p')/hyprland.log 2>/dev/null || echo 'No historical log found at position ${toString (x + 1)}'";
    }) 4
  );

  historicalCrashAliases = builtins.listToAttrs (
    builtins.genList (x: {
      name = "hlc${toString (x + 1)}";
      value = "cat ${config.xdg.cacheHome}/hyprland/$(command ls -t ${config.xdg.cacheHome}/hyprland/ | grep 'hyprlandCrashReport' | head -n ${toString (x + 2)} | tail -n 1)";
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
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = ''
        Hyprland configuration settings.

        See <https://wiki.hypr.land/Configuring/Configuring-Hyprland/>
      '';
    };
    startupCommands = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Commands to run from one `hyprland.start` event handler.
      '';
    };
  };

  imports = [
    ./apps.nix
    ./binds.nix
    ./layers.nix
    ./permissions.nix
    ./variables.nix
    ./windowrules
    ./workspacerules.nix
  ];

  config = lib.mkMerge [
    (mkIf cfg.enable {
      assertions = [
        {
          assertion = isLinux;
          message = "Hyprland is only available on linux";
        }
      ];
    })
    (mkIf (cfg.enable && isLinux) {
      home = {
        packages = with pkgs; [
          grim
          hyprpicker
          hyprprop
          hyprsysteminfo
          # NOTE: removed from nixpkgs
          # kdePackages.xwaylandvideobridge
          khanelinix.record_screen
          networkmanagerapplet
          slurp
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
            XDG_SESSION_TYPE = "wayland";
            _JAVA_AWT_WM_NONREPARENTING = "1";
            __GL_GSYNC_ALLOWED = "0";
            __GL_VRR_ALLOWED = "0";
          }
          // mkIf cfg.enableDebug {
            AQ_TRACE = "1";
            HYPRLAND_TRACE = "1";
          }
        );

        shellAliases = {
          hl = "cat $XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log";
          hlc = ''
            local report_dir="${config.xdg.cacheHome}/hyprland"
            local latest_report

            latest_report=$(command ls -t "$report_dir" 2>/dev/null | grep 'hyprlandCrashReport' | head -n 1)

            if [[ -n "$latest_report" ]]; then
                cat "''${report_dir}/''${latest_report}"
            else
                echo "No Hyprland crash reports found. ✨"
            fi
          '';
          hlw = ''watch -n 0.1 "grep -v \"arranged\" $XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log | tail -n 40"'';
        }
        // historicalLogAliases
        // historicalCrashAliases;
      };

      xdg.configFile = lib.mkIf (config.wayland.windowManager.hyprland.configType == "lua") {
        "hypr/.luacheckrc".text = ''
          read_globals = { "hl" }
        '';

        "hypr/.luarc.json" = lib.mkIf (luaLspPackage != null) {
          text = builtins.toJSON {
            workspace.library = [ "${luaLspPackage}/share/hypr/stubs" ];
            diagnostics.globals = [ "hl" ];
          };
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
              hyprlock = enabled;
            };
          };
        };

        services = {
          hypridle = enabled;

          hyprpaper = {
            enable = true;
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

      programs.hyprshot.enable = true;

      khanelinix.programs.graphical.wms.hyprland.startupCommands = lib.mkAfter [
        "notify-send --icon ${config.home.homeDirectory}/.face -u normal \"Hello $(whoami)\""
      ];

      services.hyprpolkitagent = enabled;

      systemd.user.services.hyprpolkitagent.Unit = {
        After = lib.mkAfter [ "xdg-desktop-portal.service" ];
        Wants = [ "xdg-desktop-portal.service" ];
      };

      wayland.windowManager.hyprland = lib.mkMerge [
        {
          enable = true;
          configType = "lua";

          extraConfig = ''
            ${cfg.prependConfig}

            ${cfg.appendConfig}
          '';

          # ehhhhh
          # plugins = with pkgs.hyprlandPlugins; [
          # hyprbars
          # hyprexpo
          # ];

          settings = lib.mkMerge [
            cfg.settings
            {
              on = lib.mkIf (cfg.startupCommands != [ ]) (
                lib.mkAfter [
                  {
                    _args = [
                      "hyprland.start"
                      (lib.generators.mkLuaInline ''
                        function()
                        ${lib.concatMapStringsSep "\n" (
                          command: "  hl.exec_cmd(${builtins.toJSON command})"
                        ) cfg.startupCommands}
                        end
                      '')
                    ];
                  }
                ]
              );

              config.plugin = {
                hyprexpo =
                  lib.mkIf (lib.elem pkgs.hyprlandPlugins.hyprexpo config.wayland.windowManager.hyprland.plugins)
                    {
                      columns = 3;
                      gap_size = 4;
                      bg_col = "rgb(000000)";
                    };
              };
            }
          ];

          systemd = {
            enable = !(osConfig.programs.uwsm.enable or false);
            enableXdgAutostart = true;
            extraCommands = [
              "systemctl --user stop hyprland-session.target"
              "systemctl --user reset-failed"
              "systemctl --user start hyprland-session.target"
            ];

            variables = [
              "--all"
            ];
          };

          xwayland.enable = true;
        }
        (lib.mkIf useSystemHyprland {
          package = null;
          portalPackage = null;
        })
      ];
    })
  ];
}
