{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf mkForce;
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.archetypes.wsl;
in
{
  options.khanelinix.archetypes.wsl = {
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
