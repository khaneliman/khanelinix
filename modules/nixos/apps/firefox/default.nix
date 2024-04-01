{ config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf mkMerge;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.apps.firefox;
in
{
  options.khanelinix.apps.firefox =
    {
      enable = mkBoolOpt false "Whether or not to enable Firefox.";
    };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.floorp
    ];

    services.gnome.gnome-browser-connector.enable = config.khanelinix.desktop.gnome.enable;

    khanelinix.home = {
      file = mkMerge [
        (mkIf config.khanelinix.desktop.gnome.enable {
          ".mozilla/native-messaging-hosts/org.gnome.chrome_gnome_shell.json".source = "${pkgs.chrome-gnome-shell}/lib/mozilla/native-messaging-hosts/org.gnome.chrome_gnome_shell.json";
        })
      ];
    };

    programs.firefox = {
      enable = true;
    };
  };
}
