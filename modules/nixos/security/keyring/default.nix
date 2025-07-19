{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.security.keyring;
in
{
  options.khanelinix.security.keyring = {
    enable = lib.mkEnableOption "gnome keyring";
  };

  config = mkIf cfg.enable {
    # NOTE: Also enables services.gnome.gcr-ssh-agent apparently
    services.gnome.gnome-keyring.enable = true;
  };
}
