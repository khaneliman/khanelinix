{
  config,
  lib,

  ...
}:
let
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.security.pam;
in
{
  options.khanelinix.security.pam = {
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
          value = "65536";
        }
      ];
    };
  };
}
