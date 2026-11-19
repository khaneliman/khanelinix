{ pkgs, host }:
let
  hostUnits = host.systemd.services;
  report = host.services.nginx.virtualHosts.github-triage;
  backingMounts = [
    "/mnt/disk1"
    "/mnt/disk2"
    "/mnt/disk3"
    "/mnt/disk4"
    "/mnt/cache"
    "/mnt/pool"
    "/mnt/parity"
  ];
in
pkgs.testers.runNixOSTest {
  name = "khanelilab-cutover";
  requiredFeatures.kvm = false;

  nodes.lab =
    { lib, pkgs, ... }:
    {
      # Import only the storage module, not the host's hardware or workloads.
      imports = [ ../../systems/x86_64-linux/khanelilab/storage.nix ];

      networking = {
        useDHCP = false;
        bridges.br0.interfaces = [ ];
      };
      virtualisation = {
        vlans = [ ];
        qemu.networkingOptions = lib.mkForce [ "-nic none" ];
        # The VM replaces the host fstab; keep mergerfs over disposable branches.
        fileSystems =
          lib.genAttrs backingMounts (_: {
            device = "tmpfs";
            fsType = "tmpfs";
          })
          // {
            inherit (host.fileSystems) "/mnt/user";
          };
        docker = {
          enable = true;
          # docker0 would otherwise contend with khaneproxy for a subnet.
          daemon.settings.bridge = "none";
        };
      };

      environment.systemPackages = [ pkgs.curl ];
      services = {
        nfs.server = {
          enable = true;
          exports = lib.concatLines (
            lib.filter (lib.hasPrefix "/mnt/user/appdata ") (
              lib.splitString "\n" host.services.nfs.server.exports
            )
          );
        };
        nginx = {
          enable = true;
          virtualHosts.github-triage = { inherit (report) root listen; };
        };
      };
      systemd = {
        tmpfiles.rules = [
          "f /mnt/pool/appdata/rehearsal 0644 root root - sample"
          "f /mnt/pool${lib.removePrefix "/mnt/user" report.root}/rehearsal 0644 root root - report"
        ];
        services = {
          nfs-server = {
            wantedBy = lib.mkForce [ ];
            unitConfig.RequiresMountsFor = hostUnits.nfs-server.unitConfig.RequiresMountsFor;
          };
          nfs-mountd.unitConfig.RequiresMountsFor = hostUnits.nfs-mountd.unitConfig.RequiresMountsFor;
          nginx = {
            inherit (hostUnits.nginx) after requires;
            wantedBy = lib.mkForce [ ];
            unitConfig.RequiresMountsFor = hostUnits.nginx.unitConfig.RequiresMountsFor;
          };
          khanelilab-container-networks = {
            inherit (hostUnits.khanelilab-container-networks)
              after
              requires
              wants
              serviceConfig
              script
              ;
            path = [
              pkgs.docker
              pkgs.jq
            ];
          };
          docker-immich = {
            inherit (hostUnits.docker-immich) after requires wants;
            unitConfig.RequiresMountsFor = hostUnits.docker-immich.unitConfig.RequiresMountsFor;
            serviceConfig.Type = "oneshot";
            script = "touch /run/immich-started";
          };
          libvirtd = {
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            script = "true";
          };
        }
        // lib.genAttrs [ "libvirt-HomeAssistant" "libvirt-FreeIPA" ] (name: {
          inherit (hostUnits.${name})
            after
            requires
            wants
            serviceConfig
            script
            ;
          unitConfig.RequiresMountsFor = hostUnits.${name}.unitConfig.RequiresMountsFor;
          path = [
            pkgs.coreutils
            (pkgs.writeShellScriptBin "virsh" ''
              echo "$*" >> /run/virsh.log
              if [ "$3" = domstate ]; then
                echo 'shut off'
              fi
            '')
          ];
        });
        timers = lib.genAttrs [ "snapraid-sync" "snapraid-scrub" ] (_: {
          wantedBy = lib.mkForce [ ];
        });
      };
    };

  testScript = ''
    from datetime import timedelta

    lab.wait_for_unit("multi-user.target")
    lab.fail("ip route show default | grep .")
    lab.fail("ip -6 route show default | grep .")

    with subtest("Mounted state is visible through mergerfs"):
        lab.succeed("systemctl is-active tmpfiles-mnt-pool.service", "systemctl is-active tmpfiles-mnt-user.service")
        lab.succeed("mountpoint /mnt/disk1", "mountpoint /mnt/pool", "mountpoint /mnt/user")
        lab.succeed("echo sample > /mnt/disk1/rehearsal")
        lab.succeed("grep -Fx sample /mnt/user/rehearsal")
        lab.succeed("grep -Fx sample /mnt/user/appdata/rehearsal")

    with subtest("An unavailable parity mount blocks SnapRAID jobs"):
        drop_in = "/run/systemd/system/mnt-parity.mount.d/rehearsal.conf"
        lab.succeed("systemctl stop mnt-parity.mount")
        lab.succeed(f"mkdir -p $(dirname {drop_in})")
        lab.succeed(f"printf '[Mount]\\nOptions=size=-1\\n' > {drop_in}", "systemctl daemon-reload")
        lab.fail("systemctl start snapraid-sync.service")
        lab.fail("systemctl start snapraid-scrub.service")
        for job in ("snapraid-sync", "snapraid-scrub"):
            started = lab.succeed(f"systemctl show -p ExecMainStartTimestampMonotonic --value {job}.service")
            assert started.strip() == "0", f"{job} ran without parity"
        lab.fail("test -e /mnt/parity/snapraid.parity")
        lab.succeed(f"rm {drop_in}", "systemctl daemon-reload")

    with subtest("A masked parity mount fails both SnapRAID assertions"):
        lab.succeed("systemctl mask --runtime mnt-parity.mount")
        lab.fail("mountpoint /mnt/parity")
        for job in ("snapraid-sync", "snapraid-scrub"):
            lab.fail(f"systemctl start {job}.service")
            result = lab.succeed(f"systemctl show -p AssertResult --value {job}.service")
            assert result.strip() == "no", f"{job} did not fail its mountpoint assertion"
        lab.fail("test -e /mnt/parity/snapraid.parity")
        lab.succeed("systemctl unmask --runtime mnt-parity.mount")
        lab.succeed("systemctl start snapraid-sync.service")
        lab.succeed("mountpoint /mnt/parity", "test -s /mnt/parity/snapraid.parity")

    with subtest("NFS activates the mounted tmpfiles unit before exporting appdata"):
        lab.succeed("systemctl stop tmpfiles-mnt-user.service")
        lab.succeed("systemctl start nfs-server.service")
        lab.succeed("systemctl is-active tmpfiles-mnt-user.service", "systemctl is-active nfs-server.service")
        tmpfiles_at = lab.succeed("systemctl show -p ActiveEnterTimestampMonotonic --value tmpfiles-mnt-user.service")
        nfs_at = lab.succeed("systemctl show -p InactiveExitTimestampMonotonic --value nfs-server.service")
        assert 0 < int(tmpfiles_at) <= int(nfs_at)
        lab.succeed("exportfs -s | grep '^/mnt/user/appdata[[:space:]]'")

    with subtest("Network setup is repeatable and a mismatch blocks dependents"):
        lab.fail("ip link show khaneproxy")
        lab.succeed("systemctl start nginx.service")
        lab.wait_for_open_port(80, addr="172.18.0.1", timeout=timedelta(seconds=20))
        lab.succeed("curl -fsS -H 'Host: github-triage' http://172.18.0.1/rehearsal | grep -Fx report")
        lab.succeed("systemctl start docker-immich.service")
        lab.succeed("test -e /run/immich-started")
        lab.succeed("systemctl restart khanelilab-container-networks.service")
        lab.succeed("systemctl stop nginx.service", "rm /run/immich-started")
        lab.succeed("docker network rm br0")
        lab.succeed("docker network create --driver bridge br0")
        lab.fail("systemctl restart khanelilab-container-networks.service")
        lab.fail("systemctl start docker-immich.service")
        lab.fail("systemctl start nginx.service")
        lab.fail("test -e /run/immich-started")

    with subtest("Guest startup checks copied disks and NVRAM before calling libvirt"):
        for name, disk in (
            ("HomeAssistant", "/mnt/cache/domains/Hassio/haos-recovered.qcow2"),
            ("FreeIPA", "/mnt/cache/domains/FreeIPA/vdisk1.img"),
        ):
            unit = f"libvirt-{name}.service"
            nvram = f"/var/lib/libvirt/qemu/nvram/{name}_VARS.fd"
            lab.succeed(f"mkdir -p $(dirname {disk}) $(dirname {nvram})")
            lab.succeed(f"truncate -s 131072 {nvram}")
            lab.fail(f"systemctl start {unit}")
            lab.succeed(f"echo mock > {disk}", f"truncate -s 4096 {nvram}")
            lab.fail(f"systemctl start {unit}")
            lab.fail("test -e /run/virsh.log")
            lab.succeed(f"truncate -s 131072 {nvram}; systemctl start {unit}")
            lab.succeed(f"grep -Fx -- '-c qemu:///system start {name}' /run/virsh.log")
            lab.succeed("rm /run/virsh.log")
  '';
}
