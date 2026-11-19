{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (config.khanelinix) user;

  cfg = config.khanelinix.programs.graphical.addons.looking-glass-client;
in
{
  options.khanelinix.programs.graphical.addons.looking-glass-client = {
    enable = lib.mkEnableOption "the Looking Glass client";
    enableKvmfr = lib.mkEnableOption "ivshmem support";
    vfioDevicePaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "/dev/vfio/11"
        "/dev/vfio/12"
      ];
      description = "Host-specific VFIO device nodes to add to libvirt's cgroup_device_acl.";
    };
  };

  config = mkIf cfg.enable {
    boot = lib.mkIf cfg.enableKvmfr {
      extraModulePackages = with config.boot.kernelPackages; [ kvmfr ];
      extraModprobeConfig = ''
        options kvmfr static_size_mb=256
      '';
      initrd = {
        kernelModules = [
          "kvmfr"
        ];
      };
    };

    environment.systemPackages = with pkgs; [
      looking-glass-client
    ];

    environment.etc."looking-glass-client.ini" = {
      source = ./client.ini;
    }
    // lib.optionalAttrs (user.name != null) {
      user = user.name;
    };

    # Allow user and qemu-libvirtd (both in group kvm) access to kvmfr.
    services.udev.extraRules = lib.mkIf cfg.enableKvmfr ''
      SUBSYSTEM=="kvmfr", OWNER="qemu-libvirtd", GROUP="kvm", MODE="0660"
    '';

    # Only set up /dev/shm when not using kvmfr
    systemd.tmpfiles.settings = lib.mkIf (!cfg.enableKvmfr && user.name != null) {
      "looking-glass" = {
        "/dev/shm/looking-glass".f = {
          age = "-";
          group = "kvm";
          mode = "0660";
          user = user.name;
        };
      };
    };

    virtualisation.libvirtd.qemu.verbatimConfig =
      let
        aclDevices =
          lib.optional cfg.enableKvmfr "/dev/kvmfr0"
          ++ [ "/dev/vfio/vfio" ]
          ++ cfg.vfioDevicePaths
          ++ [
            "/dev/null"
            "/dev/full"
            "/dev/zero"
            "/dev/random"
            "/dev/urandom"
            "/dev/ptmx"
            "/dev/kvm"
          ];
      in
      ''
        cgroup_device_acl = [
          ${lib.concatMapStringsSep ",\n  " builtins.toJSON aclDevices}
        ]
      '';
  };
}
