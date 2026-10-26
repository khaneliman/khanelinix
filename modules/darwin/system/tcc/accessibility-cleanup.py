import json
import os
import sqlite3
import subprocess
import tempfile

DB_PATH = "/Library/Application Support/com.apple.TCC/TCC.db"
SERVICE = "kTCCServiceAccessibility"
# codesign exits 3 when the code is validly signed but fails the -R requirement.
REQUIREMENT_UNSATISFIED = 3


def stable_clients():
    return json.loads(os.environ["KHANELINIX_TCC_STABLE_CLIENTS"])


def fails_requirement(path, csreq):
    if not os.path.exists(path):
        return True
    if csreq is None:
        return False

    # Check the stored requirement the way tccd does, so a grant recorded
    # against the signing certificate survives rebuilds.
    with tempfile.NamedTemporaryFile(suffix=".csreq") as requirement:
        requirement.write(csreq)
        requirement.flush()
        result = subprocess.run(
            ["/usr/bin/codesign", "--verify", "-R", requirement.name, path],
            check=False,
            capture_output=True,
        )
    return result.returncode == REQUIREMENT_UNSATISFIED


def main():
    stable_client_paths = stable_clients()
    stable_client_placeholders = ", ".join(["?"] * len(stable_client_paths))

    with sqlite3.connect(DB_PATH) as connection:
        rows = connection.execute(
            f"""
            select client, csreq
            from access
            where service = ?
              and client_type = 1
              and (
                client like '/nix/store/%'
                or client in ({stable_client_placeholders})
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

            if client in stable_client_paths and fails_requirement(client, csreq):
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
