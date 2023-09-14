{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.desktop.addons.kanshi;
  inherit (config.khanelinix) user;
  inherit (config.users.users.${user.name}) home;
in
{
  options.khanelinix.desktop.addons.kanshi = {
    enable =
      mkBoolOpt false "Whether to enable Kanshi in the desktop environment.";
  };

  config = mkIf cfg.enable {
    khanelinix.home.configFile."kanshi/config".source = ./config;

    environment.systemPackages = with pkgs; [ kanshi ];

    # configuring kanshi
    systemd.user.services.kanshi = {
      description = "Kanshi output autoconfig ";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      environment = { XDG_CONFIG_HOME = "${home}/.config"; };
      serviceConfig = {
        ExecCondition = ''
          ${pkgs.bash}/bin/bash -c '[ -n "$WAYLAND_DISPLAY" ]'
        '';

        ExecStart = ''
          ${pkgs.kanshi}/bin/kanshi
        '';

        RestartSec = 5;
        Restart = "always";
      };
    };
  };
}
