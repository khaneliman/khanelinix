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

    environment = {
      defaultPackages = lib.mkForce [ ];

      systemPackages = with pkgs; [
        curl
        dnsutils
        lshw
        pciutils
        pkgs.${namespace}.trace-symlink
        pkgs.${namespace}.trace-which
        rsync
        upower
        util-linux
        wget
      ];
    };

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
