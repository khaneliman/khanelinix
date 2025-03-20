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
    enable = lib.mkEnableOption "pam support";
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
