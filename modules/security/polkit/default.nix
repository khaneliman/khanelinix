{ options
, config
, pkgs
, lib
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.security.polkit;
in
{
  options.khanelinix.security.polkit = {
    enable = mkBoolOpt false "Whether or not to enable polkit.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      libsForQt5.polkit-kde-agent
    ];

    # Enable and configure `polkit`.
    security.polkit = {
      enable = true;
    };

    systemd = {
      # user.services.polkit-gnome-authentication-agent-1 = {
      #   description = "polkit-gnome-authentication-agent-1";
      #   wantedBy = [ "graphical-session.target" ];
      #   wants = [ "graphical-session.target" ];
      #   after = [ "graphical-session.target" ];
      #   serviceConfig = {
      #       Type = "simple";
      #       ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      #       Restart = "on-failure";
      #       RestartSec = 1;
      #       TimeoutStopSec = 10;
      #     };
      # };
      user.services.polkit-kde-authentication-agent-1 = {
        description = "polkit-kde-authentication-agent-1";
        wantedBy = [ "graphical-session.target" ];
        wants = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
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
