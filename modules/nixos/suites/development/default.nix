{
  config,
  lib,

  ...
}:
let
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.suites.development;
in
{
  options.khanelinix.suites.development = {
    enable = mkBoolOpt false "Whether or not to enable common development configuration.";
    azureEnable = mkBoolOpt false "Whether or not to enable azure development configuration.";
    dockerEnable = mkBoolOpt false "Whether or not to enable docker development configuration.";
    gameEnable = mkBoolOpt false "Whether or not to enable game development configuration.";
    goEnable = mkBoolOpt false "Whether or not to enable go development configuration.";
    kubernetesEnable = mkBoolOpt false "Whether or not to enable kubernetes development configuration.";
    nixEnable = mkBoolOpt false "Whether or not to enable nix development configuration.";
    sqlEnable = mkBoolOpt false "Whether or not to enable sql development configuration.";
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

      virtualisation = {
        podman.enable = cfg.dockerEnable;
      };
    };
  };
}
