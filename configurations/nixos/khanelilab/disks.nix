{
  disks ? [
    "/dev/nvme0n1"
    "/dev/nvme1n1"
    "/dev/sda"
  ],
  ...
}:
{
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
              end = "-16G";
              content = {
                type = "btrfs";
                name = "NixOS";
                extraOpenArgs = [ "--allow-discards" ];

                content = {
                  type = "btrfs";
                  # Override existing partition
                  extraArgs = [ "-f" ];

                  subvolumes = { };
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

                subvolumes = { };
              };
            };
          };
        };
      };
    };
  };
}
