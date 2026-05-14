{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    types
    mkOption
    ;
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.services.hyprpaper;
  workspaceWallpaperDir = lib.khanelinix.theme.wallpaperDir {
    inherit config pkgs;
  };
  workspaceWallpapers =
    let
      entries = builtins.readDir workspaceWallpaperDir;
      names = lib.sort lib.lessThan (lib.attrNames entries);
    in
    map (name: "${workspaceWallpaperDir}${name}") names;
  monitorWallpapers = builtins.listToAttrs (
    map (monitor: {
      inherit (monitor) name;
      value = monitor.wallpaper;
    }) cfg.monitors
  );
in
{
  options.khanelinix.services.hyprpaper = {
    enable = mkEnableOption "Hyprpaper";
    monitors = mkOption {
      description = "Monitors and their wallpapers";
      type =
        with types;
        listOf (submodule {
          options = {
            name = mkOption {
              type = str;
              description = "Monitor name (e.g. DP-1, HDMI-A-1).";
            };
            wallpaper = mkOption {
              type = path;
              description = "Wallpaper image path for this monitor.";
            };
            fitMode = mkOption {
              type = types.enum [
                "contain"
                "cover"
                "tile"
                "fill"
              ];
              default = "cover";
              description = "How the wallpaper fits this monitor (contain, cover, tile, fill).";
            };
            timeout = mkOpt types.int 30 "Timeout between each wallpaper change.";
          };
        });
    };
    wallpapers = mkOpt (types.listOf types.path) [ ] "Wallpapers to preload.";
  };

  config = mkIf cfg.enable {
    services = {
      hyprpaper = {
        # Hyprpaper documentation
        # See: https://wiki.hypr.land/Hypr-ecosystem/hyprpaper/
        enable = true;

        settings = {
          preload = cfg.wallpapers;
          wallpaper = map (monitor: {
            monitor = monitor.name;
            path = monitor.wallpaper;
            fit_mode = monitor.fitMode;
            inherit (monitor) timeout;
          }) cfg.monitors;
          splash = false;
        };
      };
    };

    wayland.windowManager.hyprland.settings.on =
      lib.mkIf
        (
          config.wayland.windowManager.hyprland.configType == "lua"
          && (workspaceWallpapers != [ ] || cfg.monitors != [ ])
        )
        (
          lib.mkAfter [
            {
              _args = [
                "workspace.active"
                (lib.generators.mkLuaInline ''
                  (function()
                    local monitorWallpapers = ${lib.generators.toLua { } monitorWallpapers}
                    local fallbackWallpapers = ${lib.generators.toLua { } workspaceWallpapers}
                    local lastApplied = {}

                    local function resolveMonitor(workspace)
                      local monitor = workspace and workspace.monitor
                      if type(monitor) == "table" and type(monitor.name) == "string" then
                        return monitor.name
                      end

                      if type(monitor) == "string" then
                        return monitor
                      end

                      local active = hl.get_active_monitor()
                      if active ~= nil and type(active.name) == "string" then
                        return active.name
                      end

                      return nil
                    end

                    return function(workspace)
                      if workspace == nil or workspace.special then
                        return
                      end

                      local workspace_id = workspace.id
                      local monitor = resolveMonitor(workspace)
                      local wallpaper

                      if type(workspace_id) ~= "number" or workspace_id < 1 then
                        return
                      end

                      wallpaper = fallbackWallpapers[math.min(workspace_id, #fallbackWallpapers)]

                      if wallpaper == nil and monitor ~= nil then
                        wallpaper = monitorWallpapers[monitor]
                      end

                      if wallpaper == nil or lastApplied[monitor] == wallpaper then
                        return
                      end

                      lastApplied[monitor] = wallpaper
                      if monitor ~= nil then
                        hl.exec_cmd("hyprctl hyprpaper wallpaper " .. monitor .. "," .. wallpaper)
                      end
                    end
                  end)()
                '')
              ];
            }
          ]
        );

    systemd.user.services.hyprpaper.Unit.ConditionEnvironment =
      lib.mkForce "HYPRLAND_INSTANCE_SIGNATURE";
  };
}
