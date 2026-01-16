---
name: managing-secrets
description: Manages encrypted secrets using sops-nix and age. Use when adding new secrets, rotating keys, debugging secret access, or setting up secret management for new hosts/users.
---

# Managing Secrets

## Overview

This project uses **sops-nix** with **age** keys for secret management. Secrets
are stored in `secrets/` and decrypted at runtime.

## Directory Structure

```
secrets/
├── <hostname>/         # Host-specific secrets
│   └── default.yaml    # Host secrets file
├── <username>/         # User-specific secrets
│   └── default.yaml    # User secrets file
└── shared/             # Shared/Global secrets
```

## Configuration (.sops.yaml)

Access rules are defined in `.sops.yaml` at the project root. Keys are defined
groups (e.g., `hosts`, `users`) and creation rules map files to key groups.

## Adding a New Secret Workflow

Copy this checklist and track your progress:

```
Secret Addition Progress:
- [ ] Step 1: Identify which file needs the secret (host/user/shared)
- [ ] Step 2: Edit the appropriate secrets file with sops
- [ ] Step 3: Add key-value pair to YAML
- [ ] Step 4: Reference in Nix module with sops.secrets
- [ ] Step 5: Verify secret path in target service
- [ ] Step 6: Test secret access after rebuild
```

### Step 1: Identify Secret Location

Decide based on scope:

- Host-specific (hostname, SSH keys) → `secrets/<hostname>/default.yaml`
- User-specific (tokens, passwords) → `secrets/<username>/default.yaml`
- Shared (API keys used everywhere) → `secrets/shared/`

### Step 2-3: Edit and Add Secret

```bash
sops secrets/<path>/default.yaml
```

Add your secret:

```yaml
my_secret_key: "super_secret_value"
```

### Step 4: Reference in Nix

```nix
sops.secrets."my_secret_key" = {
  sopsFile = lib.getFile "secrets/<path>/default.yaml";
  # Optional: specify owner, mode, etc.
};
```

### Step 5: Verify Path

System secrets: `/run/secrets/my_secret_key` Home-manager secrets:
`$XDG_RUNTIME_DIR/secrets/my_secret_key`

### Step 6: Test

After rebuild, verify the secret is accessible:

```bash
# System
sudo cat /run/secrets/my_secret_key

# Home
cat $XDG_RUNTIME_DIR/secrets/my_secret_key
```

## Additional Workflows

### Editing Secrets

To edit or view an encrypted file:

```bash
sops secrets/<path>/default.yaml
```

_Editor will open with decrypted content. Saves re-encrypt automatically._

### Rekeying (Rotating Keys)

If `.sops.yaml` rules change (e.g., adding a new host key):

```bash
# Update all secrets based on .sops.yaml rules
sops updatekeys secrets/**/*.yaml
```

## Common Issues

| Symptom                | Likely Cause                  | Solution                                                     |
| ---------------------- | ----------------------------- | ------------------------------------------------------------ |
| "File not found"       | Incorrect sopsFile path       | Use `lib.getFile` or verify relative path                    |
| "Permission denied"    | Key not in .sops.yaml         | Add host/user key to appropriate group                       |
| "Failed to decrypt"    | Wrong age key                 | Check `sops.age.keyFile` path is correct                     |
| "Secret not appearing" | Service started before secret | Add `systemd.services.<name>.after = [ "sops-nix.service" ]` |

## Debugging Tips

**"File not found"**:

- Ensure `sopsFile` path uses `lib.getFile` or relative path correctly.

**"Permission denied"**:

- Check that the host/user SSH key is in `.sops.yaml`.
- Verify the runtime key path matches `sops.age.keyFile` or
  `sops.age.sshKeyPaths`.

**Service can't read secret**:

- Verify the service runs after sops-nix:
  `systemd.services.<name>.after = [ "sops-nix.service" ]`
- Check file permissions on the secret path

## See Also

- **Configuration layers**: See [configuring-layers](../configuring-layers/) for
  understanding where to place secret references
