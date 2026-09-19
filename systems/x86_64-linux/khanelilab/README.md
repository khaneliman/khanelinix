# AustinServer migration

This host prepares a native-first replacement for AustinServer, inventoried on
2026-09-19. It is not an installation script. Nothing in this change deploys the
host, copies application state, formats disks, or starts the source workloads.

The selected storage target is mergerfs with SnapRAID for HDD media. Independent
protection for SSD application state and VM disks remains a cutover
prerequisite. Do not treat the single-device Btrfs pools or their local
snapshots as backups.

## Workload contract

The 35 running source containers map to 11 native services and 24 OCI
containers. HomeAssistant and FreeIPA remain VMs. Definitions for other
historical workloads remain available, but are not automatically started by this
host.

| Source workload                            | Target                                                                 |
| ------------------------------------------ | ---------------------------------------------------------------------- |
| Plex, Jellyfin                             | Native services, existing state and GPU access                         |
| Lidarr, Radarr, Sonarr, Prowlarr, Tautulli | Native services, retained application paths                            |
| HermesAgent                                | Native gateway, flat existing state and dedicated Docker proxy         |
| Redis                                      | Native Valkey, loopback and the private application bridge             |
| Unraid-Cloudflared-Tunnel                  | Native token-managed tunnel; routes remain remotely managed            |
| GitHub-Triage                              | Native nginx serving the existing Hermes reports                       |
| Remaining 24 containers                    | Docker, pinned to the source running image digests in `images.nix`     |
| HomeAssistant                              | Existing HAOS VM, including Supervisor; not native Home Assistant Core |
| FreeIPA                                    | Existing identity/DNS/CA VM                                            |

`workloads.nix` selects active services. `containers.nix` preserves Docker
networks, aliases and publications. `media.nix` preserves UID 99/GID 100 and
service-local `/config`, `/data`, `/media` and `/plexlogs` paths where required.
Native package versions can differ from the source containers. A successful Nix
build does not prove that an application can upgrade its existing database.

## Storage prerequisites

- Provision a separate OS disk with the layout expected by `hardware.nix`: Btrfs
  label `nixos`, subvolume `/@`, and a FAT EFI partition labelled `EFI`. The
  disabled `disks.nix` is an obsolete template, not a migration procedure.
- Verify the four data-disk UUIDs and both SSD UUIDs against `storage.nix`. They
  identify the existing filesystems and must not be reformatted.
- Provision a separate XFS filesystem labelled `snapraid-parity` for
  `/mnt/parity/snapraid.parity`. Size it for the largest protected data disk,
  including filesystem overhead. It is not a mergerfs branch.
- Reusing the existing Unraid parity disk requires a separate, deliberate
  provisioning step. Its current contents cannot be converted into SnapRAID
  parity. Repurposing it removes the old parity-based rollback path.
- Establish independent backups for `/mnt/pool/appdata`, the VM disks under
  `/mnt/cache/domains`, and other irreplaceable SSD data. Test restoration
  before cutover. No backup destination or SSD mirror is configured here.
- Audit media placement before the initial sync. mergerfs does not implement
  Unraid's Mover. Its existing-path allocation policy can place new files on an
  SSD if the parent directory exists there. Media on either SSD is outside the
  SnapRAID data set. Settle HDD placement or a deliberate transfer policy first.

The data disks are configured writable for the selected target. Merely mounting
those disks writable can replay filesystem journals and invalidate Unraid
parity. Do not boot this configuration against the live array for a read-only
rehearsal. Use isolated copies, or an explicitly read-only rehearsal
configuration instead.

SnapRAID sync runs at 03:00. Scrub runs Sunday at 04:00, covering 8% of blocks
older than 10 days. Both jobs require all data, SSD-content and parity mounts.
The combined `/mnt/user` mount also requires the parity mount.

Parity covers the last successful sync, not every write. Routine deletions are
accepted by the next sync. Stock empty-disk and UUID checks remain enabled;
there is no custom partial-deletion threshold. Appdata, VM and system
directories are excluded. SnapRAID is not a substitute for independent backups.

## State and credentials

Preserve file ownership, permissions, extended attributes and symlinks when
copying state. Shut down stateful applications and guests for the final copy.
Keep an untouched backup before any native service opens an existing database.

| Source                                                   | Destination or treatment                                                             |
| -------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| Existing `/mnt/pool/appdata` and `/mnt/user/appdata`     | Retain the existing trees; do not create empty replacement application directories   |
| `/mnt/cache/domains/Hassio/haos-recovered.qcow2`         | Same physical SSD path, used directly by HomeAssistant                               |
| `/mnt/cache/domains/FreeIPA/vdisk1.img`                  | Same physical SSD path, used directly by FreeIPA                                     |
| `/etc/libvirt/qemu/nvram/HomeAssistant_VARS-pure-efi.fd` | `/var/lib/libvirt/qemu/nvram/HomeAssistant_VARS.fd`                                  |
| `/etc/libvirt/qemu/nvram/FreeIPA_VARS-pure-efi.fd`       | `/var/lib/libvirt/qemu/nvram/FreeIPA_VARS.fd`                                        |
| `/boot/config/plugins/compose.manager/projects`          | `/mnt/pool/appdata/compose-projects`                                                 |
| Source host `/etc/ssh/ssh_host_ed25519_key`              | Preserve securely at the same destination path for host identity and SOPS decryption |

The imported NVRAM files must remain byte-for-byte intact and each be 131072
bytes. The VM definitions use compatible legacy-size OVMF firmware. Do not
replace these files with fresh firmware templates. Import the two files, not
Unraid's entire libvirt configuration or autostart directory. Systemd owns the
mount-guarded guest startup. Libvirt may change individual disk/NVRAM ownership
while a guest runs; verify parent-directory traversal on the target.

Dockge and Hermes share the copied Compose projects. `/opt/stacks` points to
that location. Review project paths before use, and do not start old stacks that
duplicate workloads now managed by NixOS.

`secrets/khanelilab/services.yaml` contains encrypted migration credentials.
System services consume runtime SOPS files, not plaintext Nix-store values. The
rclone configuration and Samba password database are seeded only when their
persistent files are absent. Later OAuth refreshes and password changes are
preserved. Replacing the encrypted seed alone does not rotate those live files.
Refresh the captured credentials before cutover if the source has changed. The
main user's pre-existing Home Manager secrets also require their personal
SSH/age identity or a deliberate rekey; the imported server key does not replace
it.

## Network and share checks

- The target assumes the same physical server and `192.168.4.42/22`, gateway
  `192.168.4.1`. Do not run source and target simultaneously with that address.
- The physical wired NIC is matched by permanent MAC and named `lan0`, then
  attached to `bond0` and `br0`. Revalidate that match if the hardware changes.
- TimeMachine retains `192.168.4.2` on the IPvlan network. Retain its LAN
  reservation and check discovery from a Mac.
- Private SMB shares are `appdata`, `data`, `isos`, `dropbox`, `google` and
  `onedrive`. The `google` share points to the actual `googledrive` mount.
- NFS exports the three local shares and four cloud mounts to `100.64.0.0/10`.
  Cloud mounts have distinct filesystem IDs and mountpoint guards. Test client
  remount/reconnect behavior; unchanged source filehandles are not promised.
- Check saved NPM upstream names, authentication redirects and Cloudflare tunnel
  routes. Cloudflare's remotely managed route configuration is not represented
  by a local catch-all ingress rule.

## Rehearsal and cutover

1. Build the target and run repository checks without activating it:

   ```sh
   nix fmt
   nix develop --command pre-commit run --all-files
   nix build .#nixosConfigurations.khanelilab.config.system.build.toplevel --no-link
   ```

2. Rehearse native services against isolated copies of their application state.
   Check database migrations, saved paths, download-client connections, library
   scans, playback and hardware transcoding. Preserve a version-compatible
   rollback copy; Nix generation rollback cannot undo a database migration.
3. Complete OS/parity provisioning and independent SSD backups. Verify source
   shutdown, final state copies, host keys, NVRAM and Compose projects.
4. Keep application writers stopped during the initial parity synchronization.
   Review `snapraid diff`, run the initial sync and check the resulting status.
   Do not resume workloads with an incomplete or failed initial sync.
5. Validate Secure Boot enrollment and retain the generated signing keys.
   Confirm the host boots and all required filesystems mount before enabling
   normal workload operation.
6. Check `systemctl --failed`, `docker ps`, `virsh list --all`, rclone user
   units, SMB/NFS access, HAOS apps, and FreeIPA DNS/Kerberos/LDAP from existing
   clients.
7. Exercise a media download/import/rename/delete cycle and verify its physical
   disk placement. Check the next SnapRAID sync and scrub logs.

No source databases were migrated, VM disks booted, hardware mounts exercised,
or source services restarted while preparing this configuration. Those runtime
checks remain required even when all build-time checks pass.
