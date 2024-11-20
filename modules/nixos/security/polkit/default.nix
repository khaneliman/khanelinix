{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.security.polkit;
in
{
  options.khanelinix.security.polkit = {
    enable = mkBoolOpt false "Whether or not to enable polkit.";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ libsForQt5.polkit-kde-agent ];

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
      user.services.polkit-kde-authentication-agent-1 = {
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
}
