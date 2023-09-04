{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.display-managers.tuigreet;
in
{
  options.khanelinix.display-managers.tuigreet = with types; {
    enable = mkBoolOpt false "Whether or not to enable tuigreet.";
  };

  config =
    mkIf cfg.enable
      {
        services.greetd = {
          enable = true;
          settings = {
            default_session = {
              command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time -r --cmd Hyprland";
              user = "greeter";
            };
          };
        };

        security.pam.services.greetd.gnupg.enable = true;
        security.pam.services.greetd.enableGnomeKeyring = true;
      };
}
