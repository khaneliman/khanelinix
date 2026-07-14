# NixOS Modules

## Main Areas

- `archetypes/`: full machine identities such as workstation, server, VM, WSL
- `suites/`: capability bundles such as desktop, NAS, observability, security
- `services/`: concrete daemons and system facilities
- `hardware/`: reusable hardware support toggles
- `display-managers/`: GDM, LightDM, regreet, SDDM, tuigreet
- `programs/`: NixOS-only application integration
- `security/`: sops, sudo/doas, PAM, polkit, audit, device security
- `system/`: boot, environment, fonts, hostname, locale, networking, time, XKB
- `virtualisation/`: KVM and Podman
- `environments/`, `home/`, `nix/`, `theme/`, `user/`: platform integration

## Ownership

- Keep system services and systemd system units here. User-session services and
  units belong in `modules/home/`.
- Put reusable, toggleable hardware support in `modules/nixos/hardware/`.
  Generated machine detection stays in `systems/<arch>/<host>/hardware.nix`.
- Reference encrypted secret sources with `lib.getFile "secrets/..."`; consume
  decrypted values through `config.sops.secrets.<name>.path`.

## Validation

```bash
nh os build
# or
nix build '.#nixosConfigurations.<host>.config.system.build.toplevel'
```

Run `nh os switch` only when task includes activating result on current host.
