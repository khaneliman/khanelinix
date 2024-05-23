{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.security.keyring;
in
{
  options.${namespace}.security.keyring = {
    enable = mkBoolOpt false "Whether to enable gnome keyring.";
  };

  config = mkIf cfg.enable { services.gnome.gnome-keyring.enable = true; };
}
