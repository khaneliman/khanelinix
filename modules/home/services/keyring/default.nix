{
  config,
  lib,

  ...
}:
let
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.services.keyring;
in
{
  options.khanelinix.services.keyring = {
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
