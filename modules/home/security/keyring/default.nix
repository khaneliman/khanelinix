{ options
, config
, lib
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt;
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
