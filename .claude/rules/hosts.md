---
paths:
  - "systems/**"
  - "homes/**"
---

# Host and User Configuration

Placement rules: `CONTRIBUTING.md` "Module Organization". Repo-specific nudges
only below.

## systems/ — per-host system config

`systems/{arch}/{hostname}/` with `default.nix` (imports, archetype selection,
host overrides) and `hardware.nix` (nixos-generate-config output; NixOS only).

Belongs here: archetype/environment selection, hardware facts, hostname and
interfaces, host-only service overrides, boot config. Anything reusable or
shared belongs in `modules/`.

```nix
khanelinix = {
  archetypes.workstation = enabled; # inherit (lib.khanelinix) enabled;
  services.ollama.enable = true;    # host override
};
```

## homes/ — per-user Home Manager config

`homes/{arch}/{user}@{host}/default.nix`.

Belongs here: user identity (name, email), monitor layouts, suite selections,
user-specific overrides, per-user sops paths. Shared user defaults belong in
`modules/home/`.

## State Version

Set once at initial setup, **never change** — it controls compatibility behavior
for stateful data:

```nix
system.stateVersion = "24.11";  # NixOS
home.stateVersion = "24.11";    # Home Manager
system.stateVersion = 5;        # Darwin
```

## Testing

```bash
nh os build|switch       # NixOS host
nh darwin build|switch   # Darwin host
```
