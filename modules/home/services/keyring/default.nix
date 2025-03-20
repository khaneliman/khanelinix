{
  config,
  lib,
  namespace,
  ...
}:
let

  cfg = config.${namespace}.services.keyring;
in
{
  options.${namespace}.services.keyring = {
    enable = lib.mkEnableOption "gnome keyring";
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
