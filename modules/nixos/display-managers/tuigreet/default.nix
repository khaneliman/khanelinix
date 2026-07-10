{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf getExe;

  cfg = config.khanelinix.display-managers.tuigreet;

  # tuigreet --remember reads /var/cache/tuigreet/lastuser (plain username,
  # trimmed); seed it so the very first login is already populated.
  seedLastUser = pkgs.writeText "tuigreet-lastuser" config.khanelinix.user.name;
in
{
  options.khanelinix.display-managers.tuigreet = {
    enable = lib.mkEnableOption "tuigreet";
  };

  config = mkIf cfg.enable {
    services.greetd = {
      # TuiGreet documentation
      # See: https://github.com/apognu/tuigreet
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

    # C = copy only when the destination is missing, so tuigreet's own
    # last-user tracking still wins after the first login (C+ would force it
    # every boot)
    systemd.tmpfiles.rules = [
      "d /var/cache/tuigreet 0755 greeter greeter"
      "C /var/cache/tuigreet/lastuser 0644 greeter greeter - ${seedLastUser}"
    ];
  };
}
