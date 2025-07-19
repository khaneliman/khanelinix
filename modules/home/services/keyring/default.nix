{
  config,
  lib,

  ...
}:
let

  cfg = config.khanelinix.services.keyring;
in
{
  options.khanelinix.services.keyring = {
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
