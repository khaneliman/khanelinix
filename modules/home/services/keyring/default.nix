{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.services.keyring;
in
{
  options.${namespace}.services.keyring = {
    enable = mkBoolOpt false "Whether to enable gnome keyring.";
  };

  config = lib.mkIf cfg.enable {
    services.gnome-keyring = {
      enable = true;

      components = [
        "pkcs11"
        "secrets"
        "ssh"
      ];
    };
  };
}
