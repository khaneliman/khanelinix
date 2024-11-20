{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf getExe;
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt;
  inherit (config.khanelinix) user;
  inherit (config.users.users.${user.name}) home;

  cfg = config.khanelinix.programs.graphical.addons.kanshi;
in
{
  options.khanelinix.programs.graphical.addons.kanshi = {
    enable = mkBoolOpt false "Whether to enable Kanshi in the desktop environment.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ kanshi ];

    xdg.configFile."kanshi/config".source = ./config;

    # configuring kanshi
    systemd.user.services.kanshi = {
      description = "Kanshi output autoconfig ";
      environment = {
        XDG_CONFIG_HOME = "${home}/.config";
      };
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        ExecCondition = # bash
          ''
            ${getExe pkgs.bash} -c '[ -n "$WAYLAND_DISPLAY" ]'
          '';

        ExecStart = # bash
          ''
            ${getExe pkgs.kanshi}
          '';

        RestartSec = 5;
        Restart = "always";
      };
    };
  };
}
