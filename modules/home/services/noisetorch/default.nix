{
  osConfig,
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) getExe mkIf mkEnableOption;

  cfg = config.${namespace}.services.noisetorch;
  osCfg = osConfig.${namespace}.programs.graphical.addons.noisetorch;
in
{
  options = {
    ${namespace}.services.noisetorch = {
      enable = mkEnableOption "noisetorch service";
    };
  };

  config = mkIf (cfg.enable && osCfg.enable) {
    systemd.user.services.noisetorch = {
      Install = {
        WantedBy = [ "default.target" ];
      };

      Unit = {
        Description = "Noisetorch Noise Cancelling";
        Requires = [ "${osCfg.deviceUnit}" ];
        After = [ "${osCfg.deviceUnit}" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${getExe osCfg.package} -i -s ${osCfg.device} -t ${builtins.toString osCfg.threshold}";
        ExecStop = "${getExe osCfg.package} -u";
        Restart = "always";
        RestartSec = 3;
        Nice = -10;
      };
    };
  };
}
