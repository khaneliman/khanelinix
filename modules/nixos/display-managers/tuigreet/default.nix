{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf getExe;

  cfg = config.khanelinix.display-managers.tuigreet;
in
{
  options.khanelinix.display-managers.tuigreet = {
    enable = lib.mkEnableOption "tuigreet";
  };

  config = mkIf cfg.enable {
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
