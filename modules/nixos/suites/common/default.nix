{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkDefault;
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
        isd
        lshw
        pciutils
        pkgs.${namespace}.trace-symlink
        pkgs.${namespace}.trace-which
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
        logind = mkDefault enabled;
        logrotate = mkDefault enabled;
        oomd = mkDefault enabled;
        openssh = mkDefault enabled;
        printing = mkDefault enabled;
        # resources-limiter = mkDefault enabled;
      };

      system = {
        fonts = mkDefault enabled;
        locale = mkDefault enabled;
        time = mkDefault enabled;
      };
    };
  };
}
