{
  config,
  lib,
  pkgs,

  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.graphical.bars.sketchybar;
  yabaiEnabled =
    osConfig.khanelinix.services.yabai.enable
      or (osConfig.khanelinix.desktop.wms.yabai.enable or false);

  userHome = config.home.homeDirectory;
  sketchybar = lib.getExe (config.programs.sketchybar.finalPackage or pkgs.sketchybar);
  finalSketchybar = config.programs.sketchybar.finalPackage or pkgs.sketchybar;
  dynamicIslandLaunchdLabel = "org.nix-community.home.dynamic-island-sketchybar";
  dynamicIslandFinalPackage = pkgs.runCommand "dynamic-island-sketchybar-final-bin" { } ''
    mkdir -p "$out/bin"
    ln -s ${lib.getExe finalSketchybar} "$out/bin/dynamic-island-sketchybar"
  '';
  dynamicIslandConfigSource = lib.cleanSourceWith {
    src = lib.cleanSource ./dynamic-island-sketchybar/.;
  };
  dynamicIslandConfig = "${userHome}/.config/dynamic-island-sketchybar/sketchybarrc";
  dynamicIslandConfigState = "${userHome}/.cache/khanelinix/dynamic-island-sketchybar-source";
  dynamicIslandLogPaths = {
    stdout = "${userHome}/Library/Logs/sketchybar/dynamic-island.out.log";
    stderr = "${userHome}/Library/Logs/sketchybar/dynamic-island.err.log";
  };
  shellAliases = {
    push = /* bash */ "command git push && ${sketchybar} --trigger git_push";
    restart-sketchybar = ''launchctl kickstart -k gui/"$(id -u)"/org.nix-community.home.sketchybar'';
  };
in
{
  options.khanelinix.programs.graphical.bars.sketchybar = {
    enable = lib.mkEnableOption "sketchybar in the desktop environment";

    dynamicIsland.keepAlive = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether launchd restarts Dynamic Island SketchyBar after it exits on macOS.
        The agent still starts when loaded if this option is disabled.
      '';
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = [
        dynamicIslandFinalPackage
      ];

      activation.restartDynamicIslandSketchybar = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
        lib.hm.dag.entryAfter
          [
            "linkGeneration"
            "setupLaunchAgents"
          ]
          ''
            restartDynamicIslandSketchybar() (
              state_file=${lib.escapeShellArg dynamicIslandConfigState}
              current_source=${lib.escapeShellArg "${dynamicIslandConfigSource}"}
              launchd_target="gui/$(id -u)/${dynamicIslandLaunchdLabel}"

              previous_source=
              if [ -f "$state_file" ]; then
                previous_source="$(cat "$state_file")"
              fi

              if [ "$previous_source" != "$current_source" ]; then
                restarted=1
                if /bin/launchctl print "$launchd_target" >/dev/null 2>&1; then
                  /bin/launchctl kickstart -k "$launchd_target" || restarted=0
                fi

                if [ "$restarted" = 1 ]; then
                  mkdir -p "$(dirname "$state_file")"
                  printf '%s\n' "$current_source" > "$state_file"
                fi
              fi
            )
            run restartDynamicIslandSketchybar
          ''
      );

      inherit shellAliases;
    };

    launchd.agents.dynamic-island-sketchybar = mkIf pkgs.stdenv.hostPlatform.isDarwin {
      enable = true;
      config = {
        EnvironmentVariables = {
          BAR_NAME = "dynamic-island-sketchybar";
          PATH = "/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin";
        };
        KeepAlive = cfg.dynamicIsland.keepAlive;
        ProcessType = "Interactive";
        ProgramArguments = [
          "/bin/sh"
          "-lc"
          "exec dynamic-island-sketchybar --config ${lib.escapeShellArg dynamicIslandConfig}"
        ];
        RunAtLoad = true;
        StandardErrorPath = dynamicIslandLogPaths.stderr;
        StandardOutPath = dynamicIslandLogPaths.stdout;
      };
    };

    programs = {
      sketchybar = {
        # Sketchybar documentation
        # See: https://felixkratz.github.io/SketchyBar/setup
        enable = true;
        configType = "lua";

        sbarLuaPackage = pkgs.sbarlua;

        extraPackages =
          with pkgs;
          [
            blueutil
            coreutils
            curl
            gh
            gh-notify
            gnugrep
            gnused
            jankyborders
            jq
            pkgs.khanelinix.clamshell
            pkgs.khanelinix.sketchyhelper
            wttrbar
          ]
          ++ lib.optionals yabaiEnabled [
            osConfig.services.yabai.package
          ]
          ++ lib.optionals config.khanelinix.programs.graphical.wms.aerospace.enable [
            config.programs.aerospace.package
          ];

        config = {
          source = ./config;
          recursive = true;
        };
      };

      zsh.initContent = /* bash */ ''
        brew() {
          command brew "$@" && ${sketchybar} --trigger brew_update
        }

        mas() {
          command mas "$@" && ${sketchybar} --trigger brew_update
        }
      '';
    };

    xdg.configFile = {
      "dynamic-island-sketchybar" = {
        source = dynamicIslandConfigSource;

        recursive = true;
      };

      "sketchybar/helpers/icon_map.lua".source =
        "${pkgs.sketchybar-app-font}/lib/sketchybar-app-font/icon_map.lua";

      "sketchybar/helpers/wm_config.lua".text = ''
        -- Window manager configuration for sketchybar
        return {
          use_aerospace = ${
            if (config.khanelinix.programs.graphical.wms.aerospace.enable or false) then "true" else "false"
          },
          use_yabai = ${if yabaiEnabled then "true" else "false"},
        }
      '';

      "sketchybar/helpers/power_config.lua".text = ''
        return {
          use_closed_lid_awake = ${
            if (osConfig.khanelinix.system.power.enable or false) then "true" else "false"
          },
          clamshell = "${lib.getExe pkgs.khanelinix.clamshell}",
        }
      '';

      "sketchybar/helpers/colors.lua".text = lib.mkDefault (
        let
          colors = config.khanelinix.theme.active;
          toLua = color: "0xff" + lib.removePrefix "#" color;
        in
        ''
          local colors = {
            base = ${toLua colors.background},
            mantle = ${toLua colors.surface},
            text = ${toLua colors.foreground},
            subtext0 = ${toLua colors.muted},
            surface0 = ${toLua colors.surfaceRaised},
            surface1 = ${toLua colors.border},
            overlay0 = ${toLua colors.subtle},
            overlay1 = ${toLua colors.subtle},
            bg2 = ${toLua colors.surface},
            grey = ${toLua colors.muted},
            white = ${toLua colors.foreground},
            blue = ${toLua colors.accent},
            green = ${toLua colors.success},
            yellow = ${toLua colors.warning},
            peach = ${toLua colors.orange},
            maroon = ${toLua colors.danger},
            red = ${toLua colors.danger},
          }

          local workspaceColors = {
            ${toLua colors.accent},
            ${toLua colors.secondary},
            ${toLua colors.tertiary},
            ${toLua colors.success},
            ${toLua colors.warning},
            ${toLua colors.orange},
            ${toLua colors.danger},
            ${toLua colors.pink},
          }

          function colors.getRandomCatColor()
            return workspaceColors[math.random(#workspaceColors)]
          end

          return colors
        ''
      );
    };

  };
}
