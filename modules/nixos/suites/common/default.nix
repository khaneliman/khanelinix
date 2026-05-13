{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib)
    getExe
    mkIf
    mkDefault
    stringAfter
    ;
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.suites.common;
in
{
  imports = [ (lib.getFile "modules/common/suites/common/default.nix") ];

  config = mkIf cfg.enable {
    environment = {
      defaultPackages = lib.mkForce [ ];

      systemPackages = with pkgs; [
        dnsutils
        fortune
        isd
        lazyjournal
        lolcat
        lshw
        pciutils
        rsync
        usbimager
        util-linux
        wget
      ];
    };

    khanelinix = {
      hardware = {
        power = mkDefault enabled;
        fans = mkDefault enabled;
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
        # auditd = mkDefault enabled;
        clamav = mkDefault enabled;
        gpg = mkDefault enabled;
        pam = mkDefault enabled;
        usbguard = mkDefault enabled;
      };

      services = {
        ananicy = mkDefault enabled;
        ddccontrol = mkDefault enabled;
        earlyoom = mkDefault enabled;
        lact = mkDefault enabled;
        logind = mkDefault enabled;
        logrotate = mkDefault enabled;
        oomd = mkDefault enabled;
        openssh = mkDefault enabled;
        printing = mkDefault enabled;
        # resources-limiter = mkDefault enabled;
      };

      system = {
        fonts = mkDefault enabled;
        hostname = mkDefault enabled;
        locale = mkDefault enabled;
        realtime = mkDefault enabled;
        time = mkDefault enabled;
      };
    };

    programs.zsh = {
      enable = true;
      autosuggestions.enable = true;
      histFile = "$XDG_CACHE_HOME/zsh.history";
    };

    system.activationScripts.reportNeedsReboot = stringAfter [ "users" ] /* Bash */ ''
      if reboot_reason=$(${getExe pkgs.khanelinix.nixos-needsreboot} --dry-run 2>&1); then
        echo "NixOS reboot check: no reboot required"
      else
        case "$?" in
          2)
            echo "NixOS reboot check: reboot required"
            echo "$reboot_reason"
            ;;
          *)
            echo "NixOS reboot check: unable to determine reboot status"
            echo "$reboot_reason"
            ;;
        esac
      fi
    '';

    zramSwap.enable = true;

    # Kernel Same-page Merging: Deduplicates identical memory pages
    # Useful for browsers, Electron apps, VMs, containers
    hardware.ksm = {
      enable = true;
      sleep = 100; # ms between scans (lower = more aggressive dedup, slightly more CPU)
    };

    # IRQBalance: Distributes hardware interrupts across CPUs for better multi-core utilization
    services.irqbalance.enable = true;
  };
}
