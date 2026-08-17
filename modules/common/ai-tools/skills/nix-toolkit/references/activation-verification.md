# Activation Verification

Confirm what a switch actually deployed. Applies to `nh os switch`,
`nh home switch`, `nixos-rebuild`, and `home-manager switch`.

## Switch Output Is Not Evidence

`nh` prints its `<<<` / `>>>` closure diff after activation and reads the "old"
side from `/run/current-system`, which activation already repointed. A real
change can therefore print one store path on both sides plus
`PATHS n -> n (+0, -0)` and `No version or size changes`.

A fast run is also not evidence of a no-op. A killed earlier run leaves its
built paths in the store, so the retry only activates.

## Compare Generations

```bash
ls -t /nix/var/nix/profiles/ | head
readlink -f /nix/var/nix/profiles/system-<previous>-link
readlink -f /nix/var/nix/profiles/system-<new>-link
```

Different targets prove the system changed. Identical targets prove the switch
was a no-op, whatever the summary claimed. Use
`~/.local/state/nix/profiles/home-manager-*-link` for a standalone Home Manager
profile.

## Prove The Intended Artifact Landed

```bash
gen=/nix/var/nix/profiles/system-<new>-link
nix path-info -r "$gen" | grep <package>
nix derivation show "$(nix path-info --derivation <store-path>)" \
  | grep <expected-input>
```

Check the derivation when the change is an input rather than a version, such as
an added patch or an overridden dependency.

## Home Manager Activation

Identify the live integrated generation in this order:

1. `~/.local/state/home-manager/gcroots/current-home`
2. `ExecStart` of `home-manager-<user>.service`
3. recent successful journal entries for that unit

A standalone `~/.local/state/nix/profiles/home-manager` may be legitimately
stale on an integrated host. Never treat it as the recovery source without
proving it matches.

Consecutive system generations that reference the same Home Manager closure
leave the oneshot unit unchanged, so it does not rerun and links stay stale.
Restart `home-manager-<user>.service` to force relinking.

Never run a live activation package under the desktop user's UID. A temporary
`HOME` does not isolate `sd-switch`: it still reaches the real `systemd --user`
manager over the user runtime bus and can stop, reload, and start production
units. Use a VM, a container with its own user manager, or a separate account.

## Reporting Checklist

- Previous and new generation store paths.
- Evidence the intended artifact is in the new closure.
- Units restarted, still stale, or left for the user.
- Collision backups produced by activation, kept until reviewed.
