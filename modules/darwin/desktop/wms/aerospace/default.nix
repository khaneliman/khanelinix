{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkOpt enabled;
  cfg = config.${namespace}.desktop.wms.aerospace;
in
{
  options.${namespace}.desktop.wms.aerospace = {
    enable = lib.mkEnableOption "aerospace";
    debug = lib.mkEnableOption "debug output";
    logFile = mkOpt lib.types.str "${
      config.snowfallorg.users.${config.${namespace}.user.name}.home.path
    }/Library/Logs/aerospace.log" "Filepath of log output";
  };

  config = lib.mkIf cfg.enable {
    ${namespace} = {
      desktop.addons.jankyborders = enabled;

      home.extraOptions = {
        home.shellAliases = {
          restart-aerospace = ''launchctl kickstart -k gui/"$(id -u)"/org.nixos.aerospace'';
        };
      };
    };

    services.aerospace = {
      enable = true;
      package = pkgs.aerospace;

      settings = {
        mode.main.binding = {
        };

        mode.resize.binding = {
        };
      };
    };
  };
}
