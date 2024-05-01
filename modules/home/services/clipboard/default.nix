{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    getExe
    getExe'
    mkEnableOption
    mkIf
    ;

  cfg = config.khanelinix.services.clipboard;
in
{
  options.khanelinix.services.clipboard = {
    enable = mkEnableOption "clipboard";
  };

  config = mkIf cfg.enable {

    systemd.user.services = {
      cliphist = {
        Install.WantedBy = [ "graphical-session.target" ];

        Unit = {
          Description = "Clipboard history service";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = "${getExe' pkgs.wl-clipboard "wl-paste"} --watch ${getExe pkgs.cliphist} store";
          Restart = "always";
        };
      };

      wl-clip-persist = {
        Install.WantedBy = [ "graphical-session.target" ];

        Unit = {
          Description = "Persistent clipboard for Wayland";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = "${getExe pkgs.wl-clip-persist} --clipboard both";
          Restart = "always";
        };
      };
    };
  };
}
