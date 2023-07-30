{ options
, config
, lib
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.security.keyring;
in
{
  options.khanelinix.security.keyring = with types; {
    enable = mkBoolOpt false "Whether to enable gnome keyring.";
  };

  config = mkIf cfg.enable {
    services.gnome-keyring = {
      enable = true;

      components = [ "pkcs11" "secrets" "ssh" ];
    };
  };
}
