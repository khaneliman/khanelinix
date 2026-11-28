# First activation after the service migration

1. Wait for active work to finish, then quit the desktop. A running desktop can
   overwrite its settings with the values it loaded before activation.
2. Stop the old service before activating. On macOS, run
   `launchctl bootout gui/$(id -u)/org.nix-community.home.t3code-remote`;
   on Linux, run `systemctl --user stop t3code-remote.service`.
   Home Manager starts new launchd jobs before removing old ones, so stopping
   the old job first avoids a temporary port and state-directory conflict.
3. Activate the new system or Home Manager generation, then reopen the desktop.
4. Run `t3 pair` on this host and open its desktop pairing link, or paste its
   pairing URL into **Settings > Environments > Add environment**. Reuse an
   existing paired connection if this service is already listed.

Leave **Local environment** off and use the service's streamed browser for
browser automation. Existing Electron website logins do not transfer to that
browser; sign in there when needed. Do not run `t3 service install` alongside
the Home Manager-managed service.

# Picking up a new build

On Linux a rebuild leaves the running server alone, because a restart stops
every running agent turn. Restart it yourself once agents are idle:

```sh
systemctl --user restart t3code
```

Until then the server runs the previous build, and a newer client may report a
version mismatch. macOS still restarts the server on activation: Home Manager
reloads a launchd agent whenever its plist changes.

# Legacy database recovery

`t3code-reconcile-migrations` is a manual recovery command for the legacy
`state.sqlite` database, not the current `statev2.sqlite` database.

# Linking machines

A link lets agents on one machine launch and drive threads on another. It needs
a one-time pairing code and expires after 30 idle days, so it is not declared.
Create or renew one from the machine whose agents should reach out:

```sh
t3-link khanelimac --access auto
```

The command mints the code on the target over SSH and passes further flags to
`t3 environment link`. Without `--access` the link is supervised, and delegated
work waits for approval of each command. Links are one-way: run it on the other
machine for the return direction. `t3 environment list` shows each link and
whether it answers.

# Remote desktop connection repair

`t3-pair <ssh-host>` creates a pairing code on the target backend. It does not
replace the credential saved by a desktop client.

For an existing connection saved by a Linux T3 desktop, run `t3-repair` on that
desktop's machine and name the backend's SSH host. From khanelimac:

```sh
ssh khanelinix t3-repair khanelimac
```

The Linux desktop must have **Local environment** off and a separate running
backend. Its logged-in user's Secret Service keyring must be available. The command uses no
screen controls. A locked keyring still prevents repair; SSH access does not
unlock it. The saved environment must be enabled and use an HTTPS bearer route.
First-time pairing still uses the affected client's Add Environment flow.

The command verifies the endpoint's environment identity and file-read grant,
then replaces only that saved connection's credential using Electron's native
encryption. It keeps an encrypted rollback copy at
`~/.t3/userdata/connection-catalog.json.t3-repair-backup`, or under the configured
`T3CODE_HOME`. Concurrent catalog changes abort the replacement.

The frontend restarts to reload the credential. Neither backend is restarted,
so running agents remain on their existing backend. Success means the exact
new session has connected, not just that a token was issued. The credential has
ordinary paired-client permissions, without access-management grants.

Focused checks:

```sh
node --test modules/home/programs/terminal/tools/t3code/repair-catalog.test.cjs
python3 -B modules/home/programs/terminal/tools/t3code/repair-connection.test.py
```

# Managed policy

`khanelinix.services.t3code.policy` installs `/etc/t3code/policy.json` on NixOS.
It turns telemetry off for the server, the desktop app, and server-opened
browsers, and marks updates as managed elsewhere, so an update a client asks for
is refused instead of failing. The NixOS development suite enables it wherever
this module is enabled. macOS has no policy yet; its server still gets telemetry
off from the service environment.

Every T3 Code server and desktop app on the host loads the file, including a
development build, and none of them starts on a key its version does not know.
A policy file also rules out running a server without authentication. The build
runs `t3 policy check` with the packaged version, so a bad policy fails the
rebuild instead. After activation and a server restart, `t3 policy show` reports
what was loaded.

# Memory protection

`khanelinix.services.t3code.protect` is the declarative form of
`t3 service protect`. That command writes drop-ins under `/etc/systemd/system`,
which NixOS does not allow, so do not run it. The NixOS development suite
enables the option wherever this module is enabled.

The NixOS half reserves memory down the user slice chain and lowers the user
manager's OOM score. This module then sets the server's own reservation and
score. `tailscaled` is protected too, so remote clients stay connected under
memory pressure.

The memory reservations apply on activation. The OOM scores apply once the user
manager restarts, which with lingering means a reboot. `t3 service status` reads
what the kernel applies: expect `Memory protection: on` and `OOM score: -900`.
It still reports the service as needing repair, because the unit is not
upstream's own.

# Storage cleanup

T3's hourly storage sweep removes a worktree when its thread was deleted,
settled, or idle for three days, or when its pull request merged. It keeps the
branch, so resuming the thread recreates the checkout without rerunning setup
scripts. It never removes a worktree with uncommitted changes or one owned by
an archived thread.

On Linux, the hourly `t3code-storage-gc` timer covers what the sweep cannot.
It works on the repositories of the projects T3 lists in
`~/.t3/userdata/statev2.sqlite` and on every worktree of those repositories:
the main checkout, T3's worktrees, and worktrees agents add themselves. No
repository is configured by name.

- It deletes `tmp_*` files untouched for an hour in `.git/objects`, its `pack`
  directory, and its loose-object directories. T3 stops a checkpoint capture
  after 30 seconds, and a capture stopped while streaming large untracked
  files leaks a partial pack.
- In `~/.t3/worktrees`, it commits the edits of a worktree idle for three days
  as a `wip:` commit on that worktree's branch, without hooks or signing, so
  the sweep can remove it. It keeps worktrees with a new file over 50 MiB, an
  untracked nested repository, hidden or unmerged index entries, an operation
  in progress, or a process working inside.
- It prunes cargo target directories: ignored directories at the top of a
  worktree that hold cargo's `.rustc_info.json`, such as `target/`.
  Everything in one is disposable (`cargo clean` deletes it all), but agents
  leave task folders there and give isolated checks their own nested target
  directories, often tens of GiB each. It deletes folders unchanged for 14
  days, unless they hold tracked files, a nested worktree or clone, or a
  process working in them. After 24 hours unchanged, it deletes cargo's own
  build folders (profiles and target triples) inside nested target
  directories, unless a build holds their `.cargo-lock` or a process works in
  them. Anything saved beside those build folders waits for the 14-day rule.
  Cargo's own folders directly under the target directory are never deleted.
  "Unchanged" means no newer modification time, so a folder copied or
  restored with its old timestamps counts as idle.

`CACHEDIR.TAG` alone does not qualify a directory: cargo omits it when the
directory already existed, and other tools tag state that is not scratch, such
as uv virtual environments.

Preview a run with `t3code-storage-gc --dry-run`. Runs log to
`journalctl --user -u t3code-storage-gc`.

Checkpoint refs (`refs/t3/orchestration-v2/checkpoints/*`) never expire; T3
deletes one only when a rewind makes it stale, and removing them by hand breaks
rewinds and turn diffs. Every checkpoint hashes untracked files, so keep large
generated files ignored or outside the working tree.

Focused check:

```sh
python3 -B modules/home/programs/terminal/tools/t3code/storage-gc.test.py
```
