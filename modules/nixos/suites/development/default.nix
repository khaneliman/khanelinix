{
  config,
  lib,

  ...
}:
let

  cfg = config.khanelinix.suites.development;
in
{
  options.khanelinix.suites.development = {
    enable = lib.mkEnableOption "common development configuration";
    aiEnable = lib.mkEnableOption "ai development configuration";
    dockerEnable = lib.mkEnableOption "docker development configuration";
    sqlEnable = lib.mkEnableOption "sql development configuration";
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
        # FIXME: broken nixpkgs
        # ollama.enable = lib.mkDefault cfg.aiEnable;
        ollama-ui.enable = lib.mkDefault cfg.aiEnable;
        # NOTE: 13 GB closure size!!
        # open-webui.enable = lib.mkDefault cfg.aiEnable;
      };

      virtualisation = {
        podman.enable = cfg.dockerEnable;
      };
    };

    nix.settings = {
      keep-derivations = true;
      keep-outputs = true;
    };
  };
}
