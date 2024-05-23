{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf getExe';
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.services.spice-vdagentd;
in
{
  options.${namespace}.services.spice-vdagentd = {
    enable = mkBoolOpt false "Whether or not to configure spice-vdagent support.";
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
