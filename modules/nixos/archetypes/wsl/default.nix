{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkForce;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.archetypes.wsl;
in
{
  options.${namespace}.archetypes.wsl = {
    enable = mkBoolOpt false "Whether or not to enable the wsl archetype.";
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

    khanelinix.system.networking.enable = mkForce false;
  };
}
