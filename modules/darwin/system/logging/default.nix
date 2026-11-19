{ config, lib, ... }:

let
  cfg = config.khanelinix.system.logging;
  userName = config.khanelinix.user.name;
  userHome = config.users.users.${userName}.home;
  homeCfg = lib.khanelinix.hmUserConfig config;
  homeAgents = homeCfg.launchd.agents or { };

  rotationEntries =
    mode: owner: group: job:
    let
      paths = map toString (
        lib.filter (path: path != null) [
          job.StandardOutPath
          job.StandardErrorPath
        ]
      );
    in
    lib.optionals (job.Disabled != true) (
      map (path: {
        logfilename = path;
        inherit mode owner group;
        count = 7;
        size = "2048";
        flags = [
          "Z"
          "C"
        ];
      }) (lib.unique (lib.remove "/dev/null" paths))
    );

  homeRotation =
    mode: name:
    let
      agent = homeAgents.${name} or { enable = false; };
    in
    lib.optionals agent.enable (rotationEntries mode userName "staff" agent.config);

  legacyHomeRotation = enabled: name: lib.optionals enabled (homeRotation "644" name);

  primaryUserRotation =
    name:
    let
      agent = config.launchd.user.agents.${name} or null;
      inherit (config.system) primaryUser;
    in
    lib.optionals (primaryUser != null && agent != null) (
      rotationEntries "600" primaryUser "staff" agent.serviceConfig
    );

  daemonRotation =
    mode: name:
    let
      daemon = config.launchd.daemons.${name} or null;
      job = daemon.serviceConfig;
      owner = lib.defaultTo "root" job.UserName;
      group = lib.defaultTo (if owner == "root" then "wheel" else null) job.GroupName;
    in
    lib.optionals (daemon != null) (rotationEntries mode owner group job);

  logPathOption =
    stream: path:
    lib.mkOption {
      type = lib.types.str;
      default = "${userHome}/Library/Logs/${path}";
      description = "Path to the ${stream} log file.";
    };

  legacyEnableOption =
    name:
    lib.mkEnableOption "${name} log rotation"
    // {
      default = config.system.newsyslog.enable;
      defaultText = lib.literalExpression "config.system.newsyslog.enable";
    };

  legacyRotationOptions = name: {
    enable = legacyEnableOption name;
    logPaths = {
      stdout = logPathOption "${name} stdout" "${name}/${name}.out.log";
      stderr = logPathOption "${name} stderr" "${name}/${name}.err.log";
    };
  };

  inherit (config.khanelinix.services) jankyborders skhd;
  inherit (config.khanelinix.programs.graphical.bars) sketchybar;
  inherit (config.khanelinix.programs.terminal.tools) atuin nh;

  bordersErrorLog =
    if lib.hasSuffix ".out.log" jankyborders.logPath then
      "${lib.removeSuffix ".out.log" jankyborders.logPath}.err.log"
    else
      "${jankyborders.logPath}.err";
in
{
  options.khanelinix = {
    system.logging.enable = lib.mkEnableOption "system logging configuration";

    # Keep the previous Darwin options as overrides for rotation and agent paths.
    services = {
      skhd = legacyRotationOptions "skhd";
      jankyborders = {
        enable = legacyEnableOption "jankyborders";
        logPath = logPathOption "jankyborders stdout" "borders/borders.out.log";
      };
    };
    programs = {
      graphical.bars.sketchybar = legacyRotationOptions "sketchybar";
      terminal.tools = {
        atuin = legacyRotationOptions "atuin";
        nh = legacyRotationOptions "nh";
      };
    };
  };

  config = {
    system.newsyslog = {
      enable = lib.mkIf cfg.enable true;
      files = lib.filterAttrs (_: entries: entries != [ ]) (
        {
          atuin-daemon = legacyHomeRotation atuin.enable "atuin-daemon";
          jankyborders = legacyHomeRotation jankyborders.enable "jankyborders";
          nh-clean = legacyHomeRotation nh.enable "nh-clean";
          skhd = legacyHomeRotation skhd.enable "skhd";
          sketchybar = legacyHomeRotation sketchybar.enable "sketchybar";
          nix-gc = daemonRotation "644" "fast-nix-gc";
          nix-optimise = daemonRotation "644" "fast-nix-optimise";
        }
        // lib.optionalAttrs config.system.newsyslog.enable {
          dynamic-island-sketchybar = homeRotation "600" "dynamic-island-sketchybar";
          exo = homeRotation "600" "exo";
          hammerspoon = homeRotation "600" "hammerspoon";
          harmonia = daemonRotation "600" "harmonia";
          lumen = lib.unique (
            lib.concatMap primaryUserRotation (
              lib.filter (lib.hasPrefix "lumen-") (builtins.attrNames config.launchd.user.agents)
            )
          );
          yabai = primaryUserRotation "yabai";
        }
      );
    };

    home-manager.sharedModules = [
      ({ config, ... }: {
        config = lib.mkIf (config.home.username == userName) {
          services.jankyborders = lib.mkIf config.services.jankyborders.enable {
            outLogFile = lib.mkDefault jankyborders.logPath;
            errorLogFile = lib.mkDefault bordersErrorLog;
          };
          programs.sketchybar.service = lib.mkIf config.programs.sketchybar.enable {
            outLogFile = lib.mkDefault sketchybar.logPaths.stdout;
            errorLogFile = lib.mkDefault sketchybar.logPaths.stderr;
          };
        };
      })
    ];
  };
}
