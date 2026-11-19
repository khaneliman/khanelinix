import argparse
import json
import socket
import subprocess
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from urllib.parse import urlsplit, urlunsplit

PROBE_TIMEOUT = 5
SSH_OPTIONS = [
    "-nTx",
    "-oBatchMode=yes",
    "-oConnectTimeout=3",
    "-oStrictHostKeyChecking=yes",
    "-oUpdateHostKeys=no",
    "-oAddKeysToAgent=no",
    "-oClearAllForwardings=yes",
    "-oForwardAgent=no",
    "-oControlPath=none",
    "-oPermitLocalCommand=no",
    "-oRemoteCommand=none",
]


def probe(command):
    try:
        result = subprocess.run(
            command,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            errors="replace",
            timeout=PROBE_TIMEOUT,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    return result.stdout if result.returncode == 0 else None


def check_host(name, host, magic_dns_suffix, current_host):
    hostname = host["hostname"]
    row = {"name": name, "system": host["system"], "status": "unavailable"}
    if current_host in (name.lower(), hostname.split(".")[0].lower()):
        return dict(row, status="local")

    routes = [("lan", name, hostname)]
    if magic_dns_suffix:
        routes.append(("magicdns", f"{name}-ts", f"{name}.{magic_dns_suffix}"))
    if address := host.get("tailscaleIp"):
        # Keep the LAN alias's SSH port and identity when using the raw IP.
        routes.append(("tailnet-ip", name, address))

    for route, alias, address in routes:
        command = [
            "ssh",
            *SSH_OPTIONS,
            f"-oHostName={address}",
            "-l",
            host["username"],
            "--",
            alias,
            "true",
        ]
        if probe(command) is not None:
            return dict(row, status="reachable", route=route, address=address)
    return row


def check_cache(substituter):
    try:
        url = urlsplit(substituter)
    except ValueError:
        return {"cache": "invalid URL", "status": "not checked"}
    if url.scheme not in ("http", "https") or not url.hostname:
        return {"cache": f"{url.scheme or 'local'} store", "status": "not checked"}

    # Nix store parameters are not HTTP query parameters. Never print or
    # forward embedded credentials when checking cache metadata.
    base = urlunsplit((url.scheme, url.netloc.rsplit("@", 1)[-1], url.path, "", ""))
    if url.username is not None:
        return {"cache": base, "status": "not checked (credentials configured)"}

    info = probe(
        [
            "curl",
            "--disable",
            "--silent",
            "--fail",
            "--location",
            "--proto-redir",
            "=http,https",
            "--globoff",
            "--connect-timeout",
            "3",
            "--max-time",
            "4",
            "--max-filesize",
            "4096",
            "--",
            f"{base.rstrip('/')}/nix-cache-info",
        ]
    )
    store_dirs = [
        line.partition(":")[2].strip()
        for line in (info or "").splitlines()
        if line.startswith("StoreDir:")
    ]
    if info is None:
        status = "unavailable"
    else:
        status = "reachable" if store_dirs == ["/nix/store"] else "invalid metadata"
    return {"cache": base, "status": status}


def main(argv=None):
    parser = argparse.ArgumentParser(
        prog="fleet-status",
        description="Check fleet SSH and the local Nix client's HTTP cache metadata.",
        epilog="Unreachable hosts and caches are reported without failing the command.",
    )
    parser.add_argument("--inventory", type=Path, required=True, help=argparse.SUPPRESS)
    parser.add_argument("--json", action="store_true", help="Print a JSON report")
    parser.add_argument(
        "--no-caches", action="store_true", help="Skip Nix cache checks"
    )
    parser.add_argument("host", nargs="*", help="Host names to check (default: all)")
    args = parser.parse_args(argv)
    inventory = json.loads(args.inventory.read_text(encoding="utf-8"))
    hosts = inventory["hosts"]
    names = list(dict.fromkeys(args.host)) if args.host else sorted(hosts)
    if unknown := [name for name in names if name not in hosts]:
        parser.error(
            f"unknown host: {', '.join(unknown)} (choose from {', '.join(sorted(hosts))})"
        )

    current_host = socket.gethostname().split(".")[0].lower()
    report = {"hosts": [], "caches": []}
    with ThreadPoolExecutor(max_workers=8) as executor:
        host_checks = [
            executor.submit(
                check_host, name, hosts[name], inventory["magicDnsSuffix"], current_host
            )
            for name in names
        ]
        if not args.no_caches:
            substituters = probe(
                [
                    "nix",
                    "--extra-experimental-features",
                    "nix-command",
                    "config",
                    "show",
                    "substituters",
                ]
            )
            if substituters is None:
                report["cache_error"] = "Could not read configured Nix substituters."
            else:
                report["caches"] = list(
                    executor.map(check_cache, dict.fromkeys(substituters.split()))
                )
        report["hosts"] = [check.result() for check in host_checks]

    if args.json:
        print(json.dumps(report, indent=2))
    else:
        for host in report["hosts"]:
            route = (
                f" via {host['route']} ({host['address']})" if "route" in host else ""
            )
            print(f"{host['name']} ({host['system']}): {host['status']}{route}")
        if not args.no_caches:
            print("\nConfigured Nix caches:")
            for cache in report["caches"]:
                print(f"{cache['cache']}: {cache['status']}")
            if "cache_error" in report:
                print(report["cache_error"])
            elif not report["caches"]:
                print("None configured.")
    return int("cache_error" in report)


if __name__ == "__main__":
    raise SystemExit(main())
