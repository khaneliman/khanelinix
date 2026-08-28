{
  config,
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
  xdgBtrfsOpts = defaultBtrfsOpts ++ [ "x-gvfs-hide" ];
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
                  "@kvm/workloads/ollama" = {
                    mountpoint = "/var/lib/private/ollama";
                    mountOptions = defaultBtrfsOpts;
                  };
                  "@kvm/workloads/llm" = {
                    mountpoint = "/var/lib/llm";
                    mountOptions = defaultBtrfsOpts;
                  };
                  "@kvm/workloads/unity" = {
                    mountpoint = "/home/${config.khanelinix.user.name}/Unity/Hub/Editor";
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
                  # TODO: decide whether to split @home and @nix subvolumes here
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
                  "@games/app-state/games" = {
                    mountpoint = "/home/${config.khanelinix.user.name}/Games";
                    mountOptions = defaultBtrfsOpts;
                  };
                  "@games/app-state/steam" = {
                    mountpoint = "/home/${config.khanelinix.user.name}/.local/share/Steam";
                    mountOptions = defaultBtrfsOpts;
                  };
                  "@games/app-state/bottles" = {
                    mountpoint = "/home/${config.khanelinix.user.name}/.local/share/bottles";
                    mountOptions = defaultBtrfsOpts;
                  };
                  "@games/app-state/lutris" = {
                    mountpoint = "/home/${config.khanelinix.user.name}/.local/share/lutris";
                    mountOptions = defaultBtrfsOpts;
                  };
                  "@games/app-state/umu" = {
                    mountpoint = "/home/${config.khanelinix.user.name}/.local/share/umu";
                    mountOptions = defaultBtrfsOpts;
                  };
                  "@games/app-state/vinegar" = {
                    mountpoint = "/home/${config.khanelinix.user.name}/.local/share/vinegar";
                    mountOptions = defaultBtrfsOpts;
                  };
                  "@games/app-state/prism-launcher" = {
                    mountpoint = "/home/${config.khanelinix.user.name}/.local/share/PrismLauncher";
                    mountOptions = defaultBtrfsOpts;
                  };
                  "@games/app-state/yuzu" = {
                    mountpoint = "/home/${config.khanelinix.user.name}/.local/share/yuzu";
                    mountOptions = defaultBtrfsOpts;
                  };
                  "@steam" = {
                    mountpoint = "/mnt/steam";
                    mountOptions = defaultBtrfsOpts;
                  };
                  "@userdata/@documents" = {
                    mountpoint = "/home/${config.khanelinix.user.name}/Documents";
                    mountOptions = xdgBtrfsOpts;
                  };
                  "@userdata/@downloads" = {
                    mountpoint = "/home/${config.khanelinix.user.name}/Downloads";
                    mountOptions = xdgBtrfsOpts;
                  };
                  "@userdata/@music" = {
                    mountpoint = "/home/${config.khanelinix.user.name}/Music";
                    mountOptions = xdgBtrfsOpts;
                  };
                  "@userdata/@pictures" = {
                    mountpoint = "/home/${config.khanelinix.user.name}/Pictures";
                    mountOptions = xdgBtrfsOpts;
                  };
                  "@userdata/@videos" = {
                    mountpoint = "/home/${config.khanelinix.user.name}/Videos";
                    mountOptions = xdgBtrfsOpts;
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
