{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.security.sudo;
in
{
  options.${namespace}.security.sudo = {
    enable = lib.mkEnableOption "sudo support";
  };

  config = lib.mkIf cfg.enable {
    security = {
      pam.services = {
        sudo_local = {
          reattach = true;
          touchIdAuth = true;
        };
      };
    };
  };
}
