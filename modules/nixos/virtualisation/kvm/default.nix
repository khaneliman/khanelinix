{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib)
    types
    mkIf
    optionalString
    getExe
    ;
  inherit (lib.khanelinix) mkOpt enabled;
  inherit (config.khanelinix) user;

  cfg = config.khanelinix.virtualisation.kvm;
in
{
  options.khanelinix.virtualisation.kvm = with types; {
    enable = lib.mkEnableOption "KVM virtualisation";
    # Use `machinectl` and then `machinectl status <name>` to
    # get the unit "*.scope" of the virtual machine.
    machineUnits = mkOpt (listOf str) [
    ] "The systemd *.scope units to wait for before starting Scream.";
    platform = mkOpt (enum [
      "amd"
      "intel"
    ]) "amd" "Which CPU platform the machine is using.";
    vfioIds = mkOpt (listOf str) [ ] "The hardware IDs to pass through to a virtual machine.";
  };

  config = mkIf cfg.enable {
    boot = {
      initrd.kernelModules = [
        "kvm-${cfg.platform}"
        "vfio"
        "vfio_iommu_type1"
        "vfio_pci"
      ];
      kernelParams = [
        "${cfg.platform}_iommu=force_isolation"
        "iommu=pt"
        "kvm.ignore_msrs=1"
      ];
      extraModprobeConfig = optionalString (
        lib.length cfg.vfioIds > 0
      ) "options vfio-pci ids=${lib.concatStringsSep "," cfg.vfioIds}";
    };

    environment.systemPackages = with pkgs; [ virt-manager ];

    # trust bridge network interface(s)
    networking.firewall.trustedInterfaces = [
      "virbr0"
      "br0"
    ];

    systemd.tmpfiles.rules = [
      "f /dev/shm/scream 0660 ${user.name} qemu-libvirtd -"
    ];

    virtualisation = {
      libvirtd = {
        enable = true;
        extraConfig = ''
          user="${user.name}"
        '';

        onBoot = "ignore";
        onShutdown = "shutdown";

        qemu = {
          package = pkgs.qemu_kvm;
          ovmf = enabled;
          swtpm.enable = true;

          verbatimConfig = ''
            s = []
            user = "+${toString config.users.users.${user.name}.uid}"
          '';
        };
      };

      spiceUSBRedirection.enable = true;
    };

    khanelinix = {
      user = {
        extraGroups = [
          "disk"
          "input"
          "kvm"
          "libvirtd"
          "qemu-libvirtd"
        ];
      };

      programs.graphical.addons = {
        looking-glass-client = {
          enable = true;
          enableKvmfr = true;
        };
      };

      home = {
        extraOptions = {
          systemd.user.services.scream = {
            Install.RequiredBy = cfg.machineUnits;

            Service = {
              ExecStart = "${getExe pkgs.scream} -n scream -o pulse -m /dev/shm/scream";
              Restart = "always";
              StartLimitBurst = "1";
            };

            Unit = {
              Description = "Scream";
              StartLimitIntervalSec = "5";
              After = [
                "libvirtd.service"
                "pipewire-pulse.service"
                "pipewire.service"
                "sound.target"
              ]
              ++ cfg.machineUnits;
            };
          };
        };
      };
    };
  };
}
