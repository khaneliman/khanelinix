{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf getExe;
  inherit (lib.internal) mkBoolOpt;
  inherit (config.khanelinix) user;
  inherit (config.users.users.${user.name}) home;

  cfg = config.khanelinix.desktop.addons.kanshi;
in
{
  options.khanelinix.desktop.addons.kanshi = {
    enable =
      mkBoolOpt false "Whether to enable Kanshi in the desktop environment.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ kanshi ];

    khanelinix.home.configFile."kanshi/config".source = ./config;

    # configuring kanshi
    systemd.user.services.kanshi = {
      description = "Kanshi output autoconfig ";
      environment = { XDG_CONFIG_HOME = "${home}/.config"; };
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        ExecCondition = ''
          ${getExe pkgs.bash} -c '[ -n "$WAYLAND_DISPLAY" ]'
        '';

        ExecStart = ''
          ${getExe pkgs.kanshi}
        '';

        RestartSec = 5;
        Restart = "always";
      };
    };
  };
}
