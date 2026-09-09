#!/usr/bin/env python3
"""Attach read-only, account-bound Codex reset inventory to CLI usage."""

import base64
import datetime as dt
import hashlib
import http.client
import json
import os
import subprocess
import sys
import tomllib
import urllib.error
import urllib.request
from dataclasses import asdict, dataclass, field
from pathlib import Path

INVENTORY_TIMEOUT = 5
FETCH_ERRORS = (
    OSError,
    ValueError,
    KeyError,
    TypeError,
    AttributeError,
    http.client.HTTPException,
    subprocess.SubprocessError,
)


@dataclass(frozen=True)
class Credentials:
    account: str
    email: str
    access_token: str = field(repr=False)

    @property
    def owner(self):
        return self.account, self.email.casefold()


def decode_credentials(raw):
    data = json.loads(raw)
    tokens = data.get("tokens") or {}
    encoded = tokens["id_token"].split(".")[1]
    claims = json.loads(base64.urlsafe_b64decode(encoded + "=" * (-len(encoded) % 4)))
    account = tokens["account_id"]
    email = claims["email"]
    access_token = tokens["access_token"]
    if not all(
        isinstance(value, str) and value for value in (account, email, access_token)
    ):
        raise ValueError("Incomplete account identity")
    return Credentials(account, email, access_token)


def read_credentials():
    home = Path(os.environ.get("CODEX_HOME") or Path.home() / ".codex").resolve()
    try:
        config_path = home / "config.toml"
        config = tomllib.loads(config_path.read_text()) if config_path.exists() else {}
        mode = config.get("cli_auth_credentials_store", "file")
        if mode not in ("file", "auto", "keyring"):
            return None
        if mode in ("auto", "keyring"):
            # Codex login/src/auth/storage.rs: service + SHA256(canonical CODEX_HOME).
            account = "cli|" + hashlib.sha256(str(home).encode()).hexdigest()[:16]
            try:
                result = subprocess.run(
                    [
                        os.environ.get("CODEXBAR_SECRET_TOOL", "secret-tool"),
                        "lookup",
                        "service",
                        "Codex Auth",
                        "username",
                        account,
                    ],
                    capture_output=True,
                    text=True,
                    timeout=2,
                    check=False,
                )
                if result.returncode == 0 and result.stdout.strip():
                    return decode_credentials(result.stdout)
            except (OSError, subprocess.TimeoutExpired):
                pass
            if mode == "keyring":
                return None
        return decode_credentials((home / "auth.json").read_text())
    except (OSError, ValueError, KeyError, IndexError, TypeError, AttributeError):
        return None


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def fetch_inventory(credentials):
    request = urllib.request.Request(
        "https://chatgpt.com/backend-api/wham/rate-limit-reset-credits",
        headers={
            "Authorization": "Bearer " + credentials.access_token,
            "ChatGPT-Account-ID": credentials.account,
            "OpenAI-Beta": "codex-1",
            "originator": "Codex Desktop",
        },
        method="GET",
    )
    # Never forward the bearer token to a redirect destination.
    with urllib.request.build_opener(NoRedirect).open(request, timeout=4) as response:
        data = json.loads(response.read(1024 * 1024))
    count = data.get("available_count")
    if type(count) is not int or count < 0 or not isinstance(data.get("credits"), list):
        raise ValueError("Invalid reset inventory")
    credits = []
    for credit in data["credits"]:
        if not isinstance(credit, dict) or not isinstance(credit.get("status"), str):
            raise TypeError("Invalid reset credit")
        expiry = credit.get("expires_at")
        if expiry is not None:
            timestamp = dt.datetime.fromisoformat(expiry)
            if timestamp.tzinfo is None:
                raise ValueError("Reset expiry has no timezone")
        credits.append({"status": credit["status"], "expires_at": expiry})
    return {
        "availableCount": count,
        "credits": credits,
        "updatedAt": dt.datetime.now(dt.UTC).isoformat(),
    }


def fetch_inventory_bounded(credentials):
    # A socket timeout alone does not bound a server that keeps sending partial data.
    result = subprocess.run(
        [sys.executable, __file__, "--fetch-inventory"],
        input=json.dumps(asdict(credentials)),
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        timeout=INVENTORY_TIMEOUT,
        check=True,
    )
    return json.loads(result.stdout)


def enrich(entries, before, after, fetch=fetch_inventory_bounded):
    if not isinstance(entries, list):
        return entries
    candidates = [
        entry
        for entry in entries
        if isinstance(entry, dict)
        and entry.get("provider") == "codex"
        and not entry.get("error")
        and isinstance(entry.get("usage"), dict)
    ]
    for entry in candidates:
        usage = entry["usage"]
        if usage.get("codexResetCredits") is not None:
            continue
        usage["codexResetCreditsUnavailable"] = True
    if before is None or after is None or before.owner != after.owner:
        return entries
    matching = []
    for entry in candidates:
        usage = entry["usage"]
        identity = usage.get("identity")
        identity = identity if isinstance(identity, dict) else {}
        email = usage.get("accountEmail") or identity.get("accountEmail")
        if isinstance(email, str) and email.casefold() == after.email.casefold():
            matching.append(entry)
    # Multi-account CLI output cannot be bound to a single active workspace.
    if len(candidates) != 1 or len(matching) != 1:
        return entries
    usage = matching[0]["usage"]
    if usage.get("codexResetCredits") is not None:
        return entries
    try:
        usage["codexResetCredits"] = fetch(after)
        usage.pop("codexResetCreditsUnavailable", None)
    except FETCH_ERRORS:
        pass
    return entries


def main():
    if sys.argv[1:] == ["--fetch-inventory"]:
        try:
            print(json.dumps(fetch_inventory(Credentials(**json.load(sys.stdin)))))
            return 0
        except FETCH_ERRORS:
            return 1
    before = read_credentials()
    result = subprocess.run(sys.argv[1:], stdout=subprocess.PIPE, check=False)
    try:
        entries = json.loads(result.stdout)
    except (ValueError, UnicodeDecodeError):
        sys.stdout.buffer.write(result.stdout)
        return result.returncode
    after = read_credentials() if before is not None else None
    print(json.dumps(enrich(entries, before, after)))
    return result.returncode


if __name__ == "__main__":
    sys.exit(main())
