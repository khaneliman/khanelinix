{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.security.pam;
in
{
  options.${namespace}.security.pam = {
    enable = mkBoolOpt false "Whether or not to configure pam.";
  };

  config = mkIf cfg.enable {
    security.pam.loginLimits = [
      {
        domain = "*";
        item = "nofile";
        type = "-";
        value = "65536";
      }

    ];
  };
}
