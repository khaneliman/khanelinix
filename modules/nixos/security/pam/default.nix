{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.security.pam;
in
{
  options.${namespace}.security.pam = {
    enable = mkBoolOpt false "Whether or not to configure pam.";
  };

  config = lib.mkIf cfg.enable {
    security.pam = {
      sshAgentAuth.enable = true;
      loginLimits = [
        {
          domain = "*";
          item = "nofile";
          type = "-";
          value = "524288";
        }
      ];
    };
  };
}
