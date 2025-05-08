{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkForce;

  cfg = config.${namespace}.archetypes.wsl;
in
{
  options.${namespace}.archetypes.wsl = {
    enable = lib.mkEnableOption "the wsl archetype";
  };

  config = mkIf cfg.enable {
    environment = {
      sessionVariables = {
        BROWSER = "wsl-open";
      };

      systemPackages = with pkgs; [
        dos2unix
        wsl-open
        wslu
      ];
    };

    khanelinix = {
      # Networking handled by host
      system.networking.enable = mkForce (!config.wsl.wslConf.network.generateResolvConf);
      # WSL Doesn't support `oomd`
      services.oomd.enable = mkForce false;
    };
  };
}
