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
      # Gnome-keyring documentation
      # See: https://wiki.gnome.org/Projects/GnomeKeyring
      enable = true;

      components = [
        "pkcs11"
        "secrets"
        "ssh"
      ];
    };
  };
}
