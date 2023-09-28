{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf getExe;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.display-managers.tuigreet;
in
{
  options.khanelinix.display-managers.tuigreet = {
    enable = mkBoolOpt false "Whether or not to enable tuigreet.";
  };

  config =
    mkIf cfg.enable
      {
        services.greetd = {
          enable = true;
          settings = {
            default_session = {
              command = "${getExe pkgs.greetd.tuigreet} --time -r --cmd Hyprland";
              user = "greeter";
            };
          };
        };

        security.pam.services.greetd = {
          enableGnomeKeyring = true;
          gnupg.enable = true;
        };
      };
}
