{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) enabled;

  cfg = config.khanelinix.suites.common;
in
{
  imports = [ ../../../shared/suites/common/default.nix ];

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      appimage-run
      clac
      feh
      jq
      khanelinix.trace-symlink
      khanelinix.trace-which
      ncdu
      toilet
      tree
      upower
      util-linux
    ];

    khanelinix = {
      hardware = {
        power = enabled;
      };

      nix = enabled;

      programs = {
        terminal = {
          tools = {
            bandwhich = enabled;
            nix-ld = enabled;
          };
        };
      };

      security = {
        auditd = enabled;
        clamav = enabled;
        gpg = enabled;
        usbguard = enabled;
      };

      services = {
        ddccontrol = enabled;
        logrotate = enabled;
        oomd = enabled;
        openssh = enabled;
        printing = enabled;
      };

      system = {
        fonts = enabled;
        locale = enabled;
        time = enabled;
      };
    };
  };
}
