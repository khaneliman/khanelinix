{ config
, lib
, pkgs
, ...
}:
let
  inherit (lib) types mkIf length optionalString concatStringsSep getExe;
  inherit (lib.internal) mkBoolOpt mkOpt enabled;
  inherit (config.khanelinix) user;

  cfg = config.khanelinix.virtualisation.kvm;
in
{
  options.khanelinix.virtualisation.kvm = with types; {
    enable = mkBoolOpt false "Whether or not to enable KVM virtualisation.";
    # Use `machinectl` and then `machinectl status <name>` to
    # get the unit "*.scope" of the virtual machine.
    machineUnits =
      mkOpt (listOf str) [ ]
        "The systemd *.scope units to wait for before starting Scream.";
    platform =
      mkOpt (enum [ "amd" "intel" ]) "amd"
        "Which CPU platform the machine is using.";
    vfioIds =
      mkOpt (listOf str) [ ]
        "The hardware IDs to pass through to a virtual machine.";
  };

  config = mkIf cfg.enable {
    boot = {
      kernelModules = [
        "kvm-${cfg.platform}"
        "vfio"
        "vfio_iommu_type1"
        "vfio_pci"
      ];
      kernelParams = [
        "${cfg.platform}_iommu=on"
        "${cfg.platform}_iommu=pt"
        "kvm.ignore_msrs=1"
      ];
      extraModprobeConfig =
        optionalString (length cfg.vfioIds > 0)
          "options vfio-pci ids=${concatStringsSep "," cfg.vfioIds}";
    };

    systemd.tmpfiles.rules = [
      "f /dev/shm/looking-glass 0660 ${user.name} qemu-libvirtd -"
      "f /dev/shm/scream 0660 ${user.name} qemu-libvirtd -"
    ];

    environment.systemPackages = with pkgs; [ virt-manager ];

    virtualisation = {
      spiceUSBRedirection.enable = true;

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
          verbatimConfig = ''
            namespaces = []
            user = "+${builtins.toString config.users.users.${user.name}.uid}"
          '';
        };
      };
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

      apps = {
        looking-glass-client = enabled;
      };

      home = {
        extraOptions = {
          systemd.user.services.scream = {
            Install.RequiredBy = cfg.machineUnits;

            Service = {
              ExecStart = "${getExe pkgs.scream} -n scream -o pulse -m /dev/shm/scream";
              Restart = "always";
              StartLimitIntervalSec = "5";
              StartLimitBurst = "1";
            };

            Unit = {
              Description = "Scream";
              After =
                [
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
