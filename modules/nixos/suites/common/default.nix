{
  config,
  lib,
  pkgs,
  root,
  ...
}:
let
  inherit (lib) mkIf mkDefault;
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.suites.common;
in
{
  imports = [ (root + "/modules/shared/suites/common/default.nix") ];

  config = mkIf cfg.enable {

    environment = {
      defaultPackages = lib.mkForce [ ];

      systemPackages = with pkgs; [
        curl
        dnsutils
        lshw
        pciutils
        pkgs.khanelinix.trace-symlink
        pkgs.khanelinix.trace-which
        rsync
        util-linux
        wget
        usbimager
      ];
    };

    khanelinix = {
      hardware = {
        power = mkDefault enabled;
      };

      nix = mkDefault enabled;

      programs = {
        terminal = {
          tools = {
            bandwhich = mkDefault enabled;
            nix-ld = mkDefault enabled;
            ssh = mkDefault enabled;
          };
        };
      };

      security = {
        auditd = mkDefault enabled;
        clamav = mkDefault enabled;
        gpg = mkDefault enabled;
        pam = mkDefault enabled;
        usbguard = mkDefault enabled;
      };

      services = {
        ddccontrol = mkDefault enabled;
        earlyoom = mkDefault enabled;
        flatpak = mkDefault enabled;
        logind = mkDefault enabled;
        logrotate = mkDefault enabled;
        # oomd = mkDefault enabled;
        openssh = mkDefault enabled;
        printing = mkDefault enabled;
      };

      system = {
        fonts = mkDefault enabled;
        locale = mkDefault enabled;
        time = mkDefault enabled;
      };
    };
  };
}
