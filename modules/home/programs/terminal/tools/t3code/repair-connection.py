import fcntl
import json
import os
import shlex
import signal
import socket
import subprocess
import sys
import tempfile
import time
import urllib.parse
import urllib.request
from pathlib import Path

# Match ordinary paired clients, not the CLI's administrative default grants.
CLIENT_SCOPES = (
    "orchestration:read",
    "orchestration:operate",
    "settings:write",
    "providers:manage",
    "environment:maintain",
    "preview:operate",
    "diagnostics:read",
    "terminal:read",
    "terminal:operate",
    "source-control:write",
    "filesystem:read",
    "filesystem:write",
    "relay:read",
)


class NoRedirects(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise RuntimeError(
            "The saved endpoint redirected; no credential was forwarded."
        )


def run(command, **kwargs):
    return subprocess.run(
        command, check=True, capture_output=True, text=True, **kwargs
    ).stdout


def remote(host, command):
    return run(
        ["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=10", "--", host, command]
    )


def request(base_url, endpoint, *, token=None):
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    req = urllib.request.Request(
        urllib.parse.urljoin(base_url, endpoint), headers=headers
    )
    with urllib.request.build_opener(NoRedirects()).open(req, timeout=10) as response:
        return json.load(response)


def keyring_names(product_name):
    # Both identities have shipped under T3 0.0.45. Prefer the installed name.
    return tuple(dict.fromkeys((product_name, "T3 Code (Alpha)", "T3 Code Alpha")))


def recover_installation(native, app_name, token):
    try:
        return native(app_name, "contains", {"token": token})["installed"]
    except (OSError, ValueError, KeyError, subprocess.SubprocessError):
        print(
            "Credential replacement could not be confirmed; the new session was retained.",
            file=sys.stderr,
        )
        return None


def session_reconnected(sessions, session_id):
    # CLI processes have an empty in-memory connection map. The backend persists
    # lastConnectedAt only when the freshly issued session actually connects.
    return any(
        s.get("sessionId") == session_id and s.get("lastConnectedAt") is not None
        for s in sessions
    )


def restart_desktop(pid, electron, desktop_root):
    # A delayed SIGTERM must not leave the frontend closed. Electron's singleton
    # lock also prevents a duplicate if the user starts the app in this interval.
    deadline = time.monotonic() + 60
    while Path(f"/proc/{pid}").exists():
        if time.monotonic() >= deadline:
            raise RuntimeError(
                "The desktop is still running; restart was not attempted."
            )
        time.sleep(0.1)
    os.execv(electron, [electron, desktop_root])


def main():
    if len(sys.argv) != 5 or sys.argv[4].startswith("-"):
        raise RuntimeError(
            "Usage: t3-repair <ssh-host> (repairs an existing desktop connection)"
        )
    electron, libsecret, native_helper, host = sys.argv[1:]
    env = os.environ.copy()
    # SSH shells do not inherit the graphical session's keyring and display address.
    for line in run(["systemctl", "--user", "show-environment"]).splitlines():
        key, _, value = line.partition("=")
        if key in {
            "DISPLAY",
            "WAYLAND_DISPLAY",
            "XDG_RUNTIME_DIR",
            "DBUS_SESSION_BUS_ADDRESS",
            "XDG_CURRENT_DESKTOP",
            "XDG_DATA_DIRS",
        }:
            env[key] = value
    env.pop("ELECTRON_RUN_AS_NODE", None)
    env["LD_LIBRARY_PATH"] = libsecret + ":" + env.get("LD_LIBRARY_PATH", "")
    base = Path(env.get("T3CODE_HOME", str(Path.home() / ".t3"))) / "userdata"
    user_data = (
        Path(env.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))) / "t3code-v2"
    )
    lock = os.readlink(user_data / "SingletonLock")
    machine, _, pid_text = lock.rpartition("-")
    if machine != socket.gethostname() or not pid_text.isdecimal():
        raise RuntimeError("The desktop lock does not belong to this machine.")
    pid = int(pid_text)
    proc = Path(f"/proc/{pid}")
    process_stat = proc.joinpath("stat").read_text().rsplit(")", 1)[1].split()[19]
    args = proc.joinpath("cmdline").read_bytes().rstrip(b"\0").decode().split("\0")
    # Electron's process title can combine argv into a single cmdline entry.
    if len(args) == 1:
        args = shlex.split(args[0])
    if len(args) != 2 or not args[1].endswith("/libexec/t3code/apps/desktop"):
        raise RuntimeError("The lock does not identify the T3 desktop process.")
    desktop_root = Path(args[1])
    metadata = json.loads(desktop_root.joinpath("package.json").read_text())
    if metadata.get("name") != "@t3tools/desktop":
        raise RuntimeError(
            "The desktop process has an unexpected application identity."
        )
    runtime = json.loads(base.joinpath("server-runtime.json").read_text())
    if runtime["pid"] == pid:
        raise RuntimeError(
            "The desktop must use a separate backend before terminal repair."
        )
    os.kill(runtime["pid"], 0)
    catalog_path = base / "connection-catalog.json"
    environment_id = remote(
        host, 'cat "${T3CODE_HOME:-$HOME/.t3}/userdata/environment-id"'
    ).strip()
    if not environment_id or "\n" in environment_id:
        raise RuntimeError("The remote environment identity is invalid.")
    cache = Path(env.get("XDG_CACHE_HOME", str(Path.home() / ".cache"))) / "t3-repair"
    cache.mkdir(mode=0o700, parents=True, exist_ok=True)
    with (
        open(cache / "repair.lock", "a") as repair_lock,
        tempfile.TemporaryDirectory(dir=cache) as temporary,
    ):
        try:
            fcntl.flock(repair_lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise RuntimeError(
                "Another connection repair is already running."
            ) from None

        def native(app_name, mode, payload=None):
            return json.loads(
                run(
                    [
                        electron,
                        "--disable-gpu",
                        native_helper,
                        app_name,
                        str(user_data) if mode == "replace" else temporary,
                        str(catalog_path),
                        environment_id,
                        mode,
                    ],
                    env=env,
                    input=json.dumps(payload) if payload else None,
                    timeout=20,
                )
            )

        product_name = metadata["productName"]
        # T3 0.0.45 changed the keyring name by removing the stage parentheses.
        # Probe both native identities, retaining the one that decrypts this catalog.
        failures = []
        for app_name in keyring_names(product_name):
            try:
                saved = native(app_name, "inspect")
                break
            except subprocess.CalledProcessError as error:
                failures.append(error)
        else:
            raise RuntimeError(
                "Cannot decrypt the saved connection using the desktop keyring."
            ) from failures[-1]

        descriptor = request(saved["httpBaseUrl"], "/.well-known/t3/environment")
        if descriptor.get("environmentId") != environment_id:
            raise RuntimeError("The saved endpoint does not match the SSH environment.")
        command = [
            "t3",
            "auth",
            "session",
            "issue",
            "--json",
            "--label",
            socket.gethostname(),
        ]
        for scope in CLIENT_SCOPES:
            command.extend(["--scope", scope])
        issued = json.loads(remote(host, shlex.join(command)))
        installed = False
        try:
            token = issued["token"]
            session = request(saved["httpBaseUrl"], "/api/auth/session", token=token)
            if not session.get("authenticated") or "filesystem:read" not in session.get(
                "permissions", session.get("scopes", [])
            ):
                raise RuntimeError("The new session does not grant file access.")
            print(
                f"Verified file access to {saved['label']}; refreshing the desktop client.",
                flush=True,
            )
            # Stop the sole catalog writer before replacing the encrypted file.
            # The separate backend must remain alive throughout.
            try:
                if (
                    os.readlink(user_data / "SingletonLock") != lock
                    or proc.joinpath("stat").read_text().rsplit(")", 1)[1].split()[19]
                    != process_stat
                ):
                    raise RuntimeError(
                        "The desktop process changed; run the repair again."
                    )
                os.kill(pid, signal.SIGTERM)
                deadline = time.monotonic() + 10
                while proc.exists():
                    if time.monotonic() >= deadline:
                        raise RuntimeError(
                            "The desktop did not exit; no credential was changed. A restart will follow if it exits within 60 seconds."
                        )
                    time.sleep(0.1)
                # No acknowledgment does not imply no write. Inspect the native
                # encrypted catalog before deciding whether to revoke this token.
                installed = None
                try:
                    native(
                        app_name, "replace", {"digest": saved["digest"], "token": token}
                    )
                    installed = True
                except (OSError, ValueError, subprocess.SubprocessError):
                    installed = recover_installation(native, app_name, token)
                    raise
            finally:
                env["T3CODE_DESKTOP_ATTACH_EXISTING"] = "1"
                env["T3CODE_PORT"] = str(runtime["port"])
                log_path = cache / "desktop-restart.log"
                fd = os.open(log_path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
                with os.fdopen(fd, "w") as log:
                    desktop = subprocess.Popen(
                        [
                            sys.executable,
                            __file__,
                            "--restart-desktop",
                            str(pid),
                            electron,
                            str(desktop_root),
                        ],
                        env=env,
                        start_new_session=True,
                        stdin=subprocess.DEVNULL,
                        stdout=log,
                        stderr=log,
                    )
        finally:
            if installed is False:
                try:
                    remote(
                        host,
                        shlex.join(
                            ["t3", "auth", "session", "revoke", issued["sessionId"]]
                        ),
                    )
                except (OSError, subprocess.SubprocessError):
                    print(
                        f"Could not revoke unused session {issued['sessionId']} on {host}.",
                        file=sys.stderr,
                    )
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            if desktop.poll() is not None:
                raise RuntimeError(f"Desktop restart failed; see {log_path}.")
            sessions = json.loads(remote(host, "t3 auth session list --json"))
            if session_reconnected(sessions, issued["sessionId"]):
                os.kill(runtime["pid"], 0)
                log_path.unlink(missing_ok=True)
                print(
                    "Connection repaired and desktop reconnected. The backend was not restarted."
                )
                return
            time.sleep(0.5)
        raise RuntimeError(
            f"Credential saved, but desktop reconnection was not confirmed; see {log_path}."
        )


if __name__ == "__main__":
    try:
        if len(sys.argv) == 5 and sys.argv[1] == "--restart-desktop":
            restart_desktop(int(sys.argv[2]), sys.argv[3], sys.argv[4])
        else:
            main()
    except (
        OSError,
        ValueError,
        KeyError,
        RuntimeError,
        subprocess.SubprocessError,
    ) as error:
        # Subprocess output may contain a pairing token; never echo it on failure.
        detail = (
            f"Command failed (exit {error.returncode})."
            if isinstance(error, subprocess.CalledProcessError)
            else str(error)
        )
        print(f"t3-repair: {detail}", file=sys.stderr)
        sys.exit(1)
