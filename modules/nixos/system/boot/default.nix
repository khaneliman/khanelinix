{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) default-attrs;

  cfg = config.khanelinix.system.boot;
  themeCfg = config.khanelinix.theme;
in
{
  options.khanelinix.system.boot = {
    enable = lib.mkEnableOption "booting";
    plymouth = lib.mkEnableOption "plymouth boot splash";
    secureBoot = lib.mkEnableOption "secure boot";
    silentBoot = lib.mkEnableOption "silent boot";
  };

  config = mkIf cfg.enable {
    environment.systemPackages =
      with pkgs;
      [
        efibootmgr
        efitools
        efivar
      ]
      ++ lib.optionals cfg.secureBoot [ sbctl ];

    boot = {
      initrd.systemd.network.wait-online.enable = false;

      kernelParams =
        lib.optionals cfg.plymouth [ "quiet" ]
        ++ lib.optionals cfg.silentBoot [
          # tell the kernel to not be verbose
          "quiet"

          # kernel log message level
          "loglevel=3" # 1: system is unusable | 3: error condition | 7: very verbose

          # udev log message level
          "udev.log_level=3"

          # lower the udev log level to show only errors or worse
          "rd.udev.log_level=3"

          # disable systemd status messages
          # rd prefix means systemd-udev will be used instead of initrd
          "systemd.show_status=auto"
          "rd.systemd.show_status=auto"

          # disable the cursor in vt to get a black screen during intermissions
          "vt.global_cursor_default=0"
        ];

      lanzaboote = mkIf cfg.secureBoot {
        enable = true;
        pkiBundle = "/var/lib/sbctl";
      };

      loader = {
        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/boot";
        };

        generationsDir.copyKernels = true;

        systemd-boot = {
          enable = !cfg.secureBoot;
          configurationLimit = 20;
          editor = false;
        };

        timeout = 1;
      };

      plymouth = {
        enable = cfg.plymouth;
        theme = lib.mkDefault "${themeCfg.selectedTheme.name}-${themeCfg.selectedTheme.variant}";
        themePackages = lib.mkDefault [ pkgs.catppuccin-plymouth ];
      };

      tmp = default-attrs {
        useTmpfs = true;
        cleanOnBoot = true;
        tmpfsSize = "50%";
      };
    };

    services.fwupd = {
      enable = true;
      daemonSettings.EspLocation = config.boot.loader.efi.efiSysMountPoint;
    };
  };
}
