{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Existing Unraid NVRAM uses the legacy 128 KiB variable-store layout.
  firmware = pkgs.OVMF.override {
    fdSize2MB = true;
    fdSize4MB = false;
  };
  domains = {
    HomeAssistant = "/mnt/cache/domains/Hassio/haos-recovered.qcow2";
    FreeIPA = "/mnt/cache/domains/FreeIPA/vdisk1.img";
  };
  xml =
    name:
    pkgs.writeText "${name}.xml" (
      lib.replaceStrings
        [ "@OVMF_CODE@" "@QEMU@" ]
        [
          "${firmware.fd}/FV/OVMF_CODE.fd"
          "${config.virtualisation.libvirtd.qemu.package}/bin/qemu-system-x86_64"
        ]
        (builtins.readFile (./domains + "/${name}.xml"))
    );
in
{
  virtualisation.libvirtd.qemu = {
    runAsRoot = false;
    verbatimConfig = lib.mkForce ''
      namespaces = []
      dynamic_ownership = 1
      remember_owner = 1
    '';
  };
  environment.etc = lib.mapAttrs' (
    name: _: lib.nameValuePair "libvirt/domains/${name}.xml" { source = xml name; }
  ) domains;
  systemd.services = lib.mapAttrs' (
    name: disk:
    lib.nameValuePair "libvirt-${name}" {
      description = "Define and start the existing ${name} guest";
      wantedBy = [ "multi-user.target" ];
      requires = [ "libvirtd.service" ];
      after = [
        "libvirtd.service"
        "network-online.target"
      ];
      wants = [ "network-online.target" ];
      unitConfig.RequiresMountsFor = [ disk ];
      restartIfChanged = false;
      stopIfChanged = false;
      path = [
        pkgs.coreutils
        config.virtualisation.libvirtd.package
      ];
      environment.LC_ALL = "C";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        test -s ${lib.escapeShellArg disk}
        test "$(stat -c %s /var/lib/libvirt/qemu/nvram/${name}_VARS.fd)" = 131072
        virsh -c qemu:///system define --validate /etc/libvirt/domains/${name}.xml
        # Autostart belongs to this mount- and NVRAM-guarded unit, not libvirtd.
        virsh -c qemu:///system autostart --disable ${name}
        case "$(virsh -c qemu:///system domstate ${name})" in
          "shut off") virsh -c qemu:///system start ${name} ;;
          "running") ;;
          *) echo "${name} is not stopped or running; inspect it before starting" >&2; exit 1 ;;
        esac
      '';
    }
  ) domains;
}
