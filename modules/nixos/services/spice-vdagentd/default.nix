{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.services.spice-vdagentd;
in {
  options.khanelinix.services.spice-vdagentd = with types; {
    enable = mkBoolOpt false "Whether or not to configure spice-vdagent support.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [pkgs.spice-vdagent];

    systemd.services.spice-vdagentd = {
      description = "spice-vdagent daemon";
      wantedBy = ["graphical.target"];
      preStart = ''
        mkdir -p "/run/spice-vdagentd/"
      '';
      serviceConfig = {
        Type = "forking";
        ExecStart = "${pkgs.spice-vdagent}/bin/spice-vdagentd";
      };
    };
  };
}
