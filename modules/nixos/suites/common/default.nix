{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.suites.common;
in
{
  imports = [ (lib.snowfall.fs.get-file "modules/shared/suites/common/default.nix") ];

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      appimage-run
      clac
      feh
      pkgs.${namespace}.trace-symlink
      pkgs.${namespace}.trace-which
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
        earlyoom = enabled;
        logrotate = enabled;
        # oomd = enabled;
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
