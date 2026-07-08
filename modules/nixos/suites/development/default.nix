{
  config,
  lib,
  pkgs,

  ...
}:
let

  cfg = config.khanelinix.suites.development;
  aiTools = import (lib.getFile "modules/common/ai-tools") { inherit lib; };
  homeCfg = config.home-manager.users.${config.khanelinix.user.name} or { };
  exoEnabled = homeCfg.services.exo.enable or false;
  exoLibp2pPort = 52416;
  tomlFormat = pkgs.formats.toml { };
in
{
  options.khanelinix.suites.development = {
    enable = lib.mkEnableOption "common development configuration";
    aiEnable = lib.mkEnableOption "ai development configuration";
    dockerEnable = lib.mkEnableOption "docker development configuration";
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
        allowedTCPPorts = [
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

    environment.etc = lib.mkIf cfg.aiEnable {
      "codex/requirements.toml".source =
        tomlFormat.generate "codex-requirements" aiTools.codex.managedRequirements;
      "codex/hooks".source = aiTools.planningWithFiles.codex.hooks + "/hooks";
      "codex/skills/planning-with-files".source = aiTools.planningWithFiles.codex.skill;
    };
  };
}
