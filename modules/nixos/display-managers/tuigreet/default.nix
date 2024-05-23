{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf getExe;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.display-managers.tuigreet;
in
{
  options.${namespace}.display-managers.tuigreet = {
    enable = mkBoolOpt false "Whether or not to enable tuigreet.";
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
