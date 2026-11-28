{
  config,
  lib,

  ...
}:
let
  cfg = config.khanelinix.suites.development;
  homeCfg = lib.khanelinix.hmUserConfig config;
  exoEnabled = homeCfg.services.exo.enable or false;
  exoLibp2pPort = 52416;
  t3codeEnabled = homeCfg.khanelinix.programs.terminal.tools.t3code.enable or false;
in
{
  imports = [ ../../../common/suites/development ];

  options.khanelinix.suites.development = {
    dockerEnable = lib.mkEnableOption "docker development configuration";
    openDevPorts = lib.mkEnableOption "opening common local development TCP ports";
    sqlEnable = lib.mkEnableOption "sql development configuration";
  };

  config = lib.mkIf cfg.enable {
    networking = {
      firewall = {
        allowedTCPPortRanges = lib.optionals exoEnabled [
          {
            from = 49153;
            to = 65535;
          }
        ];
        allowedTCPPorts =
          lib.optionals cfg.openDevPorts [
            12345
            3000
            3001
            8080
            8081
          ]
          ++ lib.optionals exoEnabled [
            52415
            exoLibp2pPort
          ];
        allowedUDPPorts = lib.optionals exoEnabled [ 52415 ];
      };
    };

    khanelinix = {
      user = {
        extraGroups = [ "git" ] ++ lib.optionals cfg.sqlEnable [ "mysql" ];
      };

      services = {
        ollama.enable = lib.mkDefault cfg.aiEnable;
        ollama-ui.enable = lib.mkDefault cfg.aiEnable;
        t3code = {
          policy.enable = lib.mkDefault t3codeEnabled;
          protect.enable = lib.mkDefault t3codeEnabled;
        };
        # NOTE: 13 GB closure size!!
        # open-webui.enable = lib.mkDefault cfg.aiEnable;
      };

      virtualisation = {
        podman.enable = cfg.dockerEnable;
      };
    };
  };
}
