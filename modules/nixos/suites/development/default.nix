{
  config,
  lib,
  namespace,
  ...
}:
let

  cfg = config.${namespace}.suites.development;
in
{
  options.${namespace}.suites.development = {
    enable = lib.mkEnableOption "common development configuration";
    azureEnable = lib.mkEnableOption "azure development configuration";
    dockerEnable = lib.mkEnableOption "docker development configuration";
    gameEnable = lib.mkEnableOption "game development configuration";
    goEnable = lib.mkEnableOption "go development configuration";
    kubernetesEnable = lib.mkEnableOption "kubernetes development configuration";
    nixEnable = lib.mkEnableOption "nix development configuration";
    sqlEnable = lib.mkEnableOption "sql development configuration";
    aiEnable = lib.mkEnableOption "ai development configuration";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      12345
      3000
      3001
      8080
      8081
    ];

    khanelinix = {
      user = {
        extraGroups = [ "git" ] ++ lib.optionals cfg.sqlEnable [ "mysql" ];
      };

      services = {
        ollama.enable = lib.mkDefault cfg.aiEnable;
        ollama-ui.enable = lib.mkDefault cfg.aiEnable;
        # NOTE: 13 GB closure size!!
        # open-webui.enable = lib.mkDefault cfg.aiEnable;
      };

      virtualisation = {
        podman.enable = cfg.dockerEnable;
      };
    };
  };
}
