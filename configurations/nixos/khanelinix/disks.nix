{
  config,
  inputs,
  lib,

  disks ? [
    "/dev/nvme0n1"
    "/dev/nvme1n1"
    "/dev/sda"
  ],
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
  imports = lib.optional (inputs.disko ? nixosModules) inputs.disko.nixosModules.disko;

  disko.devices = {
    disk = {
      nvme0 = {
        device = builtins.elemAt disks 0;
        type = "disk";
        content = {
          type = "table";
          format = "gpt";
          partitions = {
            EFI = {
              priority = 1;
              name = "EFI";
              start = "0%";
              end = "1024MiB";
              bootable = true;
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              name = "NixOS";
              end = "-64G";
              content = {
                type = "btrfs";
                name = "NixOS";
                extraOpenArgs = [ "--allow-discards" ];

                content = {
                  type = "btrfs";
                  # Override existing partition
                  extraArgs = [ "-f" ];

                  subvolumes = {
                    "@" = {
                      mountpoint = "/";
                      mountOptions = defaultBtrfsOpts;
                    };
                    "@home" = {
                      mountpoint = "/home";
                      mountOptions = defaultBtrfsOpts;
                    };
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = defaultBtrfsOpts;
                    };
                  };
                };
              };
            };
            swap = {
              size = "100%";
              content = {
                type = "swap";
                randomEncryption = true;
                resumeDevice = true; # resume from hiberation from this device
              };
            };
          };
        };
      };

      nvme1 = {
        device = builtins.elemAt disks 1;
        type = "disk";
        content = {
          type = "table";
          format = "gpt";
          partitions = {
            root = {
              size = "100%";
              type = "btrfs";
              name = "Linux";

              content = {
                type = "btrfs";
                # Override existing partition
                extraArgs = [ "-f" ];
                subvolumes = { };
              };
            };
          };
        };
      };

      sda = {
        device = builtins.elemAt disks 2;
        type = "disk";
        content = {
          type = "table";
          format = "gpt";
          partitions = {
            root = {
              size = "100%";
              type = "btrfs";
              name = "BtrProductive";

              content = {
                type = "btrfs";
                # Override existing partition
                extraArgs = [ "-f" ];

                subvolumes = {
                  "@games" = {
                    mountpoint = "/mnt/games";
                    mountOptions = defaultBtrfsOpts;
                  };
                  "@kvm" = {
                    mountpoint = "/mnt/kvm";
                    mountOptions = defaultBtrfsOpts;
                  };
                  "@steam" = {
                    mountpoint = "/mnt/steam";
                    mountOptions = defaultBtrfsOpts;
                  };
                  "@userdata/@documents" = {
                    mountpoint = "/home/${config.snowfallorg.users.name}/Documents";
                    mountOptions = defaultBtrfsOpts;
                  };
                  "@userdata/@downloads" = {
                    mountpoint = "/home/${config.snowfallorg.users.name}/Downloads";
                    mountOptions = defaultBtrfsOpts;
                  };
                  "@userdata/@music" = {
                    mountpoint = "/home/${config.snowfallorg.users.name}/Music";
                    mountOptions = defaultBtrfsOpts;
                  };
                  "@userdata/@pictures" = {
                    mountpoint = "/home/${config.snowfallorg.users.name}/Pictures";
                    mountOptions = defaultBtrfsOpts;
                  };
                  "@userdata/@videos" = {
                    mountpoint = "/home/${config.snowfallorg.users.name}/Videos";
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
