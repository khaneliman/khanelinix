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
  useLimine = cfg.loader == "limine";
  useSystemdBoot = cfg.loader == "systemd-boot";
in
{
  options.khanelinix.system.boot = {
    enable = lib.mkEnableOption "booting";
    loader = lib.mkOption {
      type = lib.types.enum [
        "systemd-boot"
        "limine"
      ];
      default = "systemd-boot";
      description = "Bootloader to install for this host.";
    };
    limine.resolution = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "1920x1080x32";
      description = "Framebuffer resolution for Limine Linux boot entries on this host.";
    };
    plymouth = lib.mkEnableOption "plymouth boot splash";
    secureBoot = lib.mkEnableOption "secure boot";
    silentBoot = lib.mkEnableOption "silent boot";
  };

  config = mkIf cfg.enable {
    environment.systemPackages =
      with pkgs;
      [
        efibootmgr
        # FIXME: broken nixpkgs
        # https://github.com/NixOS/nixpkgs/issues/512925
        # efitools
        efivar
      ]
      ++ lib.optionals cfg.secureBoot [ sbctl ];

    boot = {
      initrd.systemd.network.wait-online.enable = false;

      kernel.sysctl = {
        # Memory management - Desktop optimized
        "vm.swappiness" = 10;
        "vm.vfs_cache_pressure" = 50;
        "vm.dirty_ratio" = 15;
        "vm.dirty_background_ratio" = 5;

        # Memory overcommit - heuristic overcommit prevents unpredictable OOMs
        # 0 = heuristic overcommit, default behavior
        "vm.overcommit_memory" = 0;
        "vm.overcommit_ratio" = 50;

        # Swap I/O optimization - read 8 pages at a time
        "vm.page-cluster" = 3;

        # Disable zone reclaim (bad for desktop, causes latency spikes)
        "vm.zone_reclaim_mode" = 0;

        # Security: prevent NULL pointer dereference attacks
        "vm.mmap_min_addr" = 65536;
      };

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

      lanzaboote = mkIf (useSystemdBoot && cfg.secureBoot) {
        enable = true;
        autoEnrollKeys = {
          enable = true;
          # Automatically reboot to enroll the keys in the firmware
          # autoReboot = true;
        };
        autoGenerateKeys.enable = true;
        pkiBundle = "/var/lib/sbctl";
      };

      loader = {
        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/boot";
        };

        generationsDir.copyKernels = true;

        systemd-boot = {
          enable = useSystemdBoot && !cfg.secureBoot;
          configurationLimit = 20;
          editor = false;
        };

        limine = mkIf useLimine {
          enable = true;
          enableEditor = false;
          maxGenerations = 10;
          inherit (cfg.limine) resolution;
          secureBoot = mkIf cfg.secureBoot {
            enable = true;
            autoGenerateKeys = true;
            autoEnrollKeys.enable = true;
            inherit (pkgs) sbctl;
          };
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
