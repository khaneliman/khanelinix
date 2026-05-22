import os
import re
import sqlite3
import subprocess

DB_PATH = "/Library/Application Support/com.apple.TCC/TCC.db"
SERVICE = "kTCCServiceAccessibility"
STABLE_CLIENTS = [
    os.path.expanduser("~/.local/bin/skhd-stable"),
    os.path.expanduser("~/.local/bin/yabai-stable"),
]


def cdhash(path):
    if not os.path.exists(path):
        return None

    result = subprocess.run(
        ["/usr/bin/codesign", "-d", "-r-", path],
        check=False,
        capture_output=True,
        text=True,
    )
    output = result.stdout + result.stderr
    match = re.search(r'cdhash H"([0-9a-fA-F]+)"', output)
    return match.group(1).upper() if match else None


def write_summary(message):
    summary_path = os.environ.get("KHANELINIX_TCC_ACCESSIBILITY_SUMMARY")
    if not summary_path:
        return

    with open(summary_path, "w", encoding="utf-8") as handle:
        handle.write(message)


def write_changed(changed):
    changed_path = os.environ.get("KHANELINIX_TCC_ACCESSIBILITY_CHANGED")
    if not changed_path:
        return

    with open(changed_path, "w", encoding="utf-8") as handle:
        handle.write("1" if changed else "0")


def main():
    with sqlite3.connect(DB_PATH) as connection:
        rows = connection.execute(
            """
            select client, hex(csreq)
            from access
            where service = ?
              and client_type = 1
              and (
                client like '/nix/store/%'
                or client in (?, ?)
              )
            """,
            (SERVICE, *STABLE_CLIENTS),
        ).fetchall()

        stale_clients = set()
        for client, csreq in rows:
            if client.startswith("/nix/store/"):
                if not os.path.exists(client):
                    stale_clients.add(client)
                continue

            if client in STABLE_CLIENTS:
                current_cdhash = cdhash(client)
                if current_cdhash is None or current_cdhash not in csreq:
                    stale_clients.add(client)

        stale_clients = sorted(stale_clients)

        if not stale_clients:
            write_changed(False)
            write_summary("No stale Accessibility TCC entries found.")
            return

        connection.executemany(
            """
            delete from access
            where service = ?
              and client_type = 1
              and client = ?
            """,
            [(SERVICE, client) for client in stale_clients],
        )

    write_changed(True)
    write_summary(
        "Pruned "
        + str(len(stale_clients))
        + " stale Accessibility TCC entries: "
        + ", ".join(stale_clients)
    )


if __name__ == "__main__":
    main()
