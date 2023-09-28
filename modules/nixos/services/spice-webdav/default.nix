{ config
, pkgs
, lib
, ...
}:
let
  inherit (lib) types mkIf mkOption getExe';
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.services.spice-webdav;
in
{
  options.khanelinix.services.spice-webdav = with types; {
    enable = mkBoolOpt false "Whether or not to configure spice-webdav proxy support.";
    package = mkOption {
      default = pkgs.phodav;
      defaultText = literalExpression "pkgs.phodav";
      description = lib.mdDoc "spice-webdavd provider package to use.";
      type = types.package;
    };
  };

  config = mkIf cfg.enable {
    services = {
      # ensure the webdav fs this exposes can actually be mounted
      davfs2.enable = true;

      # add the udev rule which starts the proxy when the spice socket is present
      udev.packages = [ cfg.package ];
    };

    systemd.services.spice-webdavd = {
      description = "spice-webdav proxy daemon";

      serviceConfig = {
        Type = "simple";
        ExecStart = "${getExe' cfg.package "spice-webdavd"} -p 9843";
        Restart = "on-success";
      };

      wantedBy = [ "graphical.target" ];
    };
  };
}
