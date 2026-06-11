---
paths:
  - "modules/nixos/**"
---

# NixOS System Modules

Placement rules: `CONTRIBUTING.md` "Module Organization" and "Platform Module
Taxonomy". Repo-specific nudges only below.

## Categories

- **archetypes/**: gaming, workstation, server, vm, wsl
- **hardware/**: audio, bluetooth, cpu, gpu, power, storage
- **display-managers/**: gdm, sddm, regreet, tuigreet
- **security/**: sops, sudo, gpg, polkit, pam
- **services/**: openssh, tailscale, printing, flatpak
- **system/**: boot, networking, locale, fonts

## Repo Nudges

- systemd **user** units belong in `modules/home/` (Home Manager), not here;
  only system units live in this tree.
- Secrets: `sops.secrets.<name> = { sopsFile = lib.getFile "secrets/..."; }` —
  never in the Nix store as plaintext.
- Prefer `DynamicUser = true` for services; firewall via
  `khanelinix.system.networking.firewall.enable`.
- Toggleable hardware support lives in `modules/nixos/hardware/`; generated
  detection output stays in `systems/{arch}/{host}/hardware.nix`.

## Testing

```bash
nh os build   # or: nix build .#nixosConfigurations.${host}.config.system.build.toplevel
nh os switch
```
