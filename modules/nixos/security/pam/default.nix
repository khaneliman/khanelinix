{
  config,
  lib,
  namespace,
  ...
}:
let

  cfg = config.${namespace}.security.pam;
in
{
  options.${namespace}.security.pam = {
    enable = lib.mkEnableOption "pam";
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
