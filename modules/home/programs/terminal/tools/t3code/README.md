# Remote desktop connection repair

`t3-pair <ssh-host>` creates a pairing code on the target backend. It does not
replace the credential saved by a desktop client.

For an existing connection saved by a Linux T3 desktop, run `t3-repair` on that
desktop's machine and name the backend's SSH host. From khanelimac:

```sh
ssh khanelinix t3-repair khanelimac
```

The Linux desktop must be running with a separate canonical backend, and its
logged-in user's Secret Service keyring must be available. The command uses no
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
