import errno
import json
import os
import sqlite3
import subprocess
import sys
import tempfile
from contextlib import closing
from pathlib import Path

DB_PATH = "/Library/Application Support/com.apple.TCC/TCC.db"
SERVICE = "kTCCServiceAccessibility"
# codesign exits 3 when the code is validly signed but fails the -R requirement.
REQUIREMENT_UNSATISFIED = 3


def stable_clients():
    return json.loads(os.environ["KHANELINIX_TCC_STABLE_CLIENTS"])


def is_missing(path):
    try:
        os.stat(path)
    except (FileNotFoundError, NotADirectoryError):
        return True
    return False


def fails_requirement(path, csreq):
    if is_missing(path):
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
    if result.returncode == REQUIREMENT_UNSATISFIED:
        return True
    if result.returncode != 0:
        print(
            f"Warning: keeping Accessibility TCC entry for {path}: "
            f"codesign exited {result.returncode}: "
            f"{result.stderr.decode(errors='replace').strip()}",
            file=sys.stderr,
        )
    return False


def prune_stale_clients(database):
    stable_client_paths = stable_clients()
    stable_client_placeholders = ", ".join(["?"] * len(stable_client_paths))

    with (
        closing(sqlite3.connect(database, uri=True, timeout=1)) as connection,
        connection,
    ):
        # Keep the audit and deletes in one snapshot so they cannot remove a
        # grant that tccd replaced after the audit read it.
        connection.execute("begin")
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
                if is_missing(client):
                    stale_clients.add(client)
                continue

            if client in stable_client_paths and fails_requirement(client, csreq):
                stale_clients.add(client)

        stale_clients = sorted(stale_clients)
        if stale_clients:
            connection.executemany(
                """
                delete from access
                where service = ?
                  and client_type = 1
                  and client = ?
                """,
                [(SERVICE, client) for client in stale_clients],
            )
    return stale_clients


def main():
    try:
        # SQLite can report CANTOPEN for SIP denial or for unrelated failures.
        # Probe the existing file without writing so we can distinguish errno.
        with open(DB_PATH, "r+b"):
            pass
    except FileNotFoundError:
        print("Skipping Accessibility TCC audit: system TCC database is missing.")
        return
    except OSError as error:
        if error.errno not in (errno.EACCES, errno.EPERM, errno.EROFS):
            raise
        print(f"Warning: skipping Accessibility TCC audit: {error}", file=sys.stderr)
        return

    database = Path(DB_PATH).as_uri() + "?mode=rw"
    try:
        stale_clients = prune_stale_clients(database)
    except sqlite3.OperationalError as error:
        code = getattr(error, "sqlite_errorcode", 0)
        primary_code = code & 0xFF
        if primary_code not in (
            sqlite3.SQLITE_BUSY,
            sqlite3.SQLITE_LOCKED,
        ) and code not in (
            sqlite3.SQLITE_PERM,
            sqlite3.SQLITE_READONLY,
            sqlite3.SQLITE_READONLY_CANTINIT,
            sqlite3.SQLITE_READONLY_CANTLOCK,
            sqlite3.SQLITE_READONLY_DIRECTORY,
            sqlite3.SQLITE_READONLY_RECOVERY,
        ):
            raise
        print(f"Warning: skipping Accessibility TCC audit: {error}", file=sys.stderr)
        return

    if not stale_clients:
        print("No stale Accessibility TCC entries found.")
        return

    print(
        "Pruned "
        + str(len(stale_clients))
        + " stale Accessibility TCC entries: "
        + ", ".join(stale_clients)
    )


if __name__ == "__main__":
    main()
