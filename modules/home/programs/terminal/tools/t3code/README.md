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
