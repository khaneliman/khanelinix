{
  config,
  khanelinix-lib,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (khanelinix-lib) mkBoolOpt mkOpt enabled;
  cfg = config.${namespace}.desktop.wms.aerospace;
in
{
  options.${namespace}.desktop.wms.aerospace = {
    enable = mkBoolOpt false "Whether or not to enable aerospace.";
    debug = mkBoolOpt false "Whether to enable debug output.";
    logFile =
      mkOpt lib.types.str "/Users/khaneliman/Library/Logs/aerospace.log"
        "Filepath of log output";
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
