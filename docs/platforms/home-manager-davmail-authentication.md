# DavMail Work Account Authentication

## Purpose

DavMail exposes the Microsoft 365 work account to local clients through IMAP,
SMTP, and CalDAV. Thunderbird and vdirsyncer both connect to DavMail on
localhost.

Microsoft account authentication and the local DavMail password are different:

- Microsoft device-code authentication creates the OAuth refresh token.
- `davmail/work-password` in SOPS is the local bridge password.
- DavMail encrypts the persisted OAuth token with the bridge password.
- Every localhost client must supply the same bridge password. Do not use the
  Microsoft account password for these prompts.

Using different saved passwords can create overlapping device-code flows. One
client may continue working while another repeatedly tries to replace the token.

## Prepare Thunderbird

Before first enrollment, or when replacing an incorrect saved password, stop the
sync path and open Thunderbird offline:

```bash
systemctl --user stop \
  vdirsyncer-davmail.timer \
  vdirsyncer-davmail.service \
  davmail.service
thunderbird --offline
```

In Thunderbird:

1. Open **Settings → Privacy & Security → Saved Passwords**.
2. Remove work-account entries for `localhost` or `127.0.0.1`.
3. Close Thunderbird completely.
4. Confirm no background process remains with `pgrep -af thunderbird`.

Open `secrets/khaneliman/default.yaml` with `sops` when the bridge password is
needed. Do not print the secret into terminal history or logs.

## Enroll or repair the account

Run:

```bash
work-calendar-auth
```

The command:

1. Stops the work-calendar timer and sync service.
2. Starts DavMail and follows its journal in the terminal.
3. Runs vdirsyncer collection discovery for every configured DavMail account.
4. Runs one work-calendar synchronization.
5. Restarts the timer only after synchronization succeeds.

If DavMail needs a new OAuth token, follow the Microsoft device-login URL and
enter the displayed code using the work account. If the existing token decrypts
successfully, no Microsoft prompt appears; this is normal.

Output such as this is also normal for the current flat-calendar configuration:

```text
Saved for calendar_davmail_<account>: collections = null
```

The primary calendar is synchronized. Other remote collections shown during
discovery, such as a holiday calendar, are not separately mapped by this
configuration.

## Reopen Thunderbird

After `work-calendar-auth` exits successfully, reopen Thunderbird. Enter the
SOPS `davmail/work-password` value for every localhost prompt and save it. IMAP,
SMTP, and CalDAV must all use that same value.

An unexpected device-code flow after successful enrollment usually means a
localhost client still has the wrong saved password. Do not complete that second
flow. Stop DavMail, correct the saved credentials offline, then run
`work-calendar-auth` again.

## Verify

```bash
systemctl --user show vdirsyncer-davmail.service \
  -p Result -p ExecMainStatus
systemctl --user list-timers vdirsyncer-davmail.timer
stat ~/.local/state/vdirsyncer/davmail-last-success
```

Expected service result:

```text
Result=success
ExecMainStatus=0
```

`vdirsyncer-davmail.service` is a oneshot service. `inactive (dead)` after a
successful run is normal. The timer runs at 5, 20, 35, and 50 minutes past each
hour.

## Failure behavior

A failed scheduled sync:

- stops `vdirsyncer-davmail.timer`;
- writes `~/.local/state/vdirsyncer/davmail-failed`;
- sends one desktop notification; and
- waits for `work-calendar-auth` to succeed before resuming the timer.

Inspect recent failures with:

```bash
journalctl --user \
  -u davmail.service \
  -u vdirsyncer-davmail.service \
  --since=-15m --no-pager
```

`Unable to decrypt token, invalid password` means a client supplied a different
bridge password from the one that encrypted the token. Correct all saved
localhost credentials before resetting OAuth state.

## Reset OAuth state

Reset the token only after confirming every client uses the SOPS bridge
password:

```bash
systemctl --user stop \
  vdirsyncer-davmail.timer \
  vdirsyncer-davmail.service \
  davmail.service
mv ~/.local/state/davmail/oauth-tokens.properties \
  ~/.local/state/davmail/oauth-tokens.properties.bak-"$(date +%Y%m%d-%H%M%S)"
work-calendar-auth
```

This forces one new Microsoft device-code enrollment while retaining the old
token file as a backup.
