{ options
, config
, lib
, pkgs
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
    environment.systemPackages = with pkgs; [
      gnome.libgnome-keyring
    ];

    services.gnome.gnome-keyring.enable = true;
  };
}
