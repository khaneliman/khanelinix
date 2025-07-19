{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf getExe';

  cfg = config.khanelinix.services.spice-vdagentd;
in
{
  options.khanelinix.services.spice-vdagentd = {
    enable = lib.mkEnableOption "spice-vdagent support";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.spice-vdagent ];

    systemd.services.spice-vdagentd = {
      description = "spice-vdagent daemon";

      preStart = # bash
        ''
          mkdir -p "/run/spice-vdagentd/"
        '';

      serviceConfig = {
        Type = "forking";
        ExecStart = "${getExe' pkgs.spice-vdagent "spice-vdagentd"}";
      };

      wantedBy = [ "graphical.target" ];
    };
  };
}
