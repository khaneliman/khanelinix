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
        fortune
        isd
        lazyjournal
        lolcat
        lshw
        pciutils
        pkgs.${namespace}.trace-symlink
        pkgs.${namespace}.trace-which
        rsync
        usbimager
        util-linux
        wget
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
        # auditd = mkDefault enabled;
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

    programs.zsh = {
      enable = true;
      autosuggestions.enable = true;
      histFile = "$XDG_CACHE_HOME/zsh.history";
    };

    zramSwap.enable = true;
  };
}
