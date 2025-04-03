{
  config,
  disks ? [
    "/dev/nvme0n1"
    "/dev/nvme1n1"
    "/dev/sda"
  ],
  namespace,
  ...
}:
let
  defaultBtrfsOpts = [
    "defaults"
    "compress=zstd:1"
    "ssd"
    "noatime"
    "nodiratime"
  ];
in
{
  disko.devices = {
    disk = {
      nvme0 = {
        device = builtins.elemAt disks 0;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            efi = {
              priority = 1;
              name = "efi";
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
                extraArgs = [
                  "-LEFI"
                ];
              };
            };
            linux = {
              size = "100%";
              name = "linux";

              content = {
                type = "btrfs";
                extraArgs = [ "-LLinux" ];
                subvolumes = {
                  "@kvm" = {
                    mountpoint = "/mnt/kvm";
                    mountOptions = defaultBtrfsOpts;
                  };
                };
              };
            };
            swap = {
              size = "64GB";
              content = {
                type = "swap";
                discardPolicy = "both";
                randomEncryption = true;
                resumeDevice = true;
                extraArgs = [
                  "-Lswap"
                ];
              };
            };
          };
        };
      };

      nvme1 = {
        device = builtins.elemAt disks 1;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            nixos = {
              name = "nixos";
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [
                  "-Lnixos"
                ];

                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = defaultBtrfsOpts;
                  };
                  # TODO:
                  # "@home" = {
                  #   mountpoint = "/home";
                  #   mountOptions = defaultBtrfsOpts;
                  # };
                  # "@nix" = {
                  #   mountpoint = "/nix";
                  #   mountOptions = defaultBtrfsOpts;
                  # };
                };
              };
            };
          };
        };
      };

      sda = {
        device = builtins.elemAt disks 2;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            root = {
              size = "100%";
              name = "btrproductive";

              content = {
                type = "btrfs";
                # Override existing partition
                extraArgs = [ "-f" ];

                subvolumes = {
                  "@games" = {
                    mountpoint = "/mnt/games";
                    mountOptions = defaultBtrfsOpts;
                  };
                  "@steam" = {
                    mountpoint = "/mnt/steam";
                    mountOptions = defaultBtrfsOpts;
                  };
                  "@userdata/@documents" = {
                    mountpoint = "/home/${config.${namespace}.user.name}/Documents";
                    mountOptions = defaultBtrfsOpts;
                  };
                  "@userdata/@downloads" = {
                    mountpoint = "/home/${config.${namespace}.user.name}/Downloads";
                    mountOptions = defaultBtrfsOpts;
                  };
                  "@userdata/@music" = {
                    mountpoint = "/home/${config.${namespace}.user.name}/Music";
                    mountOptions = defaultBtrfsOpts;
                  };
                  "@userdata/@pictures" = {
                    mountpoint = "/home/${config.${namespace}.user.name}/Pictures";
                    mountOptions = defaultBtrfsOpts;
                  };
                  "@userdata/@videos" = {
                    mountpoint = "/home/${config.${namespace}.user.name}/Videos";
                    mountOptions = defaultBtrfsOpts;
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
