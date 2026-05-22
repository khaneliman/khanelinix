import os
import re
import sqlite3
import subprocess

DB_PATH = "/Library/Application Support/com.apple.TCC/TCC.db"
SERVICE = "kTCCServiceAccessibility"


def stable_clients():
    user_home = os.environ["KHANELINIX_TCC_ACCESSIBILITY_USER_HOME"]
    return [
        os.path.join(user_home, ".local/bin/skhd-stable"),
        os.path.join(user_home, ".local/bin/yabai-stable"),
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


def main():
    stable_client_paths = stable_clients()

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
            (SERVICE, *stable_client_paths),
        ).fetchall()

        stale_clients = set()
        for client, csreq in rows:
            if client.startswith("/nix/store/"):
                if not os.path.exists(client):
                    stale_clients.add(client)
                continue

            if client in stable_client_paths:
                current_cdhash = cdhash(client)
                if current_cdhash is None or current_cdhash not in csreq:
                    stale_clients.add(client)

        stale_clients = sorted(stale_clients)

        if not stale_clients:
            print("No stale Accessibility TCC entries found.")
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

    print(
        "Pruned "
        + str(len(stale_clients))
        + " stale Accessibility TCC entries: "
        + ", ".join(stale_clients)
    )


if __name__ == "__main__":
    main()
