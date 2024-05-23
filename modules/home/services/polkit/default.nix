{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.${namespace}.services.polkit;
in
{
  options.${namespace}.services.polkit = {
    enable = mkEnableOption "polkit";
  };

  config = mkIf cfg.enable {

    systemd.user.services = {
      polkit-kde-authentication-agent-1 = {
        Install.WantedBy = [ "graphical-session.target" ];

        Unit = {
          Description = "polkit service";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = "${pkgs.libsForQt5.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1";
          Restart = "always";
        };
      };
    };
  };
}
