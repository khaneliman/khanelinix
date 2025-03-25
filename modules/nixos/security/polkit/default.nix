{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.security.polkit;
in
{
  options.${namespace}.security.polkit = {
    enable = lib.mkEnableOption "polkit";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      with pkgs;
      lib.optionals (!config.${namespace}.programs.graphical.wms.hyprland.enable) [
        kdePackages.polkit-kde-agent
      ];

    security.polkit = {
      enable = true;
      debug = lib.mkDefault true;

      extraConfig = lib.mkIf config.security.polkit.debug ''
        /* Log authorization checks. */
        polkit.addRule(function(action, subject) {
          polkit.log("user " +  subject.user + " is attempting action " + action.id + " from PID " + subject.pid);
        });
      '';
    };

    systemd = {
      user.services = {
        polkit-kde-authentication-agent-1 =
          lib.mkIf (!config.${namespace}.programs.graphical.wms.hyprland.enable)
            {
              after = [ "graphical-session.target" ];
              description = "polkit-kde-authentication-agent-1";
              wantedBy = [ "graphical-session.target" ];
              wants = [ "graphical-session.target" ];
              serviceConfig = {
                Type = "simple";
                ExecStart = "${pkgs.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1";
                Restart = "on-failure";
                RestartSec = 1;
                TimeoutStopSec = 10;
              };
            };
      };
    };
  };
}
