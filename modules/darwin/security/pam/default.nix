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
    enable = mkBoolOpt false "Whether or not to configure pam support.";
  };

  config = lib.mkIf cfg.enable {
    security.pam.services = {
      sudo_local = {
        reattach = true;
        touchIdAuth = true;
      };
    };
  };
}
