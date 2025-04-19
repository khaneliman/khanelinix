{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (config.${namespace}) user;

  cfg = config.${namespace}.programs.graphical.addons.looking-glass-client;
in
{
  options.${namespace}.programs.graphical.addons.looking-glass-client = {
    enable = lib.mkEnableOption "the Looking Glass client";
    enableKvmfr = lib.mkEnableOption "ivshmem support";
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
      user = "+${toString config.users.users.${user.name}.uid}";
      source = ./client.ini;
    };

    # Allow user to have access to kvmfr interface
    services.udev.extraRules = lib.mkIf cfg.enableKvmfr ''
      SUBSYSTEM=="kvmfr", OWNER="${user.name}", GROUP="kvm", MODE="0660"
      SUBSYSTEM=="kvmfr", OWNER="qemu-libvirtd", GROUP="kvm", MODE="0660"
    '';

    # Only set up /dev/shm when not using kvmfr
    systemd.tmpfiles.settings = lib.mkIf (!cfg.enableKvmfr) {
      "looking-glass" = {
        "/dev/shm/looking-glass".f = {
          age = "-";
          group = "kvm";
          mode = "0660";
          user = toString config.users.users.${user.name}.uid;
        };
      };
    };

    virtualisation.libvirtd.qemu.verbatimConfig = ''
      cgroup_device_acl = [
        ${lib.optionalString cfg.enableKvmfr "\"dev/kvmfr0\","}
        "/dev/vfio/vfio", "/dev/vfio/11", "/dev/vfio/12",
        "/dev/null", "/dev/full", "/dev/zero",
        "/dev/random", "/dev/urandom",
        "/dev/ptmx", "/dev/kvm"
      ]
    '';
  };
}
