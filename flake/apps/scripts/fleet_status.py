import argparse
import json
import shlex
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


# NUL-delimited records keep multiline systemctl/JSON output inside one field.
# Print the marker first so a slow observation does not discard the route or
# completed fields when the client deadline expires.
HEALTH_PROBE = r"""
export LC_ALL=C
field() { printf '%s\0%s\0' "$1" "$2"; }
field protocol fleet-health-v1
active=/run/current-system
target=$(readlink "$active") && field active_system "$target"
case "$1" in
  darwin)
    revision=$("$active/sw/bin/darwin-version" --configuration-revision) &&
      field active_revision "$revision"
    ;;
  nixos)
    revision=$("$active/sw/bin/nixos-version" --configuration-revision) &&
      field active_revision "$revision"
    "$active/sw/bin/nixos-needsreboot" --dry-run >/dev/null
    case $? in
      0) field needs_reboot no ;;
      2) field needs_reboot yes ;;
    esac
    units=$(timeout 1 systemctl list-units --failed --all --output=json --no-pager) &&
      field failed_units "$units"
    for job in sync scrub; do
      state=$(timeout 1 systemctl show "snapraid-$job.service" --no-pager \
        -p LoadState -p Result -p ExecMainExitTimestamp -p ActiveState) &&
        field "snapraid_$job" "$state"
    done
    if timeout 1 systemctl is-active --quiet scrutiny.service; then
      summary=$(curl --disable --noproxy '*' --silent --fail --max-time 1 \
        --max-filesize 1048576 http://127.0.0.1:8080/api/summary) &&
        field disk_health "$summary"
    fi
    ;;
esac
exit 0
"""


def health_report(output):
    fields = {
        name: "unknown"
        for name in (
            "active_system",
            "active_revision",
            "needs_reboot",
            "failed_units",
            "disk_health",
        )
    }
    fields["snapraid"] = {"sync": "unknown", "scrub": "unknown"}
    records = (output or "").split("\0")[:-1]
    if records[:2] != ["protocol", "fleet-health-v1"]:
        return fields
    values = dict(zip(records[::2], records[1::2], strict=False))
    for key in ("active_system", "active_revision"):
        if values.get(key) and values[key] not in ("null", "unknown"):
            fields[key] = values[key]
    if values.get("needs_reboot") in ("yes", "no"):
        fields["needs_reboot"] = values["needs_reboot"] == "yes"
    if "failed_units" in values:
        try:
            units = json.loads(values["failed_units"])
            if isinstance(units, list) and all(
                isinstance(unit, dict) and isinstance(unit.get("unit"), str)
                for unit in units
            ):
                fields["failed_units"] = [unit["unit"] for unit in units]
        except ValueError:
            pass
    for job in ("sync", "scrub"):
        properties = dict(
            line.split("=", 1)
            for line in values.get(f"snapraid_{job}", "").splitlines()
            if "=" in line
        )
        if properties.get("LoadState") != "loaded":
            continue
        if properties.get("ActiveState") in ("active", "activating"):
            fields["snapraid"][job] = "running"
        elif properties.get("ExecMainExitTimestamp") and properties.get("Result"):
            fields["snapraid"][job] = {
                "last_result": properties["Result"],
                "finished_at": properties["ExecMainExitTimestamp"],
            }
    if "disk_health" in values:
        fields["disk_health"] = disk_summary(values["disk_health"])
    return fields


def disk_summary(payload):
    states = {
        0: "passed",
        1: "SMART failure",
        2: "Scrutiny failure",
        3: "SMART and Scrutiny failure",
    }
    try:
        response = json.loads(payload)
        if response["success"] is not True:
            return "unknown"
        disks = []
        for entry in response["data"]["summary"].values():
            device = entry["device"]
            if device.get("archived"):
                continue
            observed = (entry.get("smart") or {}).get("collector_date")
            disks.append(
                {
                    "device": device["device_name"],
                    "collector_host": device.get("host_id") or "unknown",
                    "last_status": states.get(device.get("device_status"), "unknown")
                    if observed
                    else "unknown",
                    "observed_at": observed or "unknown",
                }
            )
        return disks or "unknown"
    except (ValueError, KeyError, AttributeError, TypeError):
        return "unknown"


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
    except subprocess.TimeoutExpired as error:
        partial = (error.stdout or b"").decode(errors="replace")
        return partial if partial.startswith("protocol\0fleet-health-v1\0") else None
    except OSError:
        return None
    return result.stdout if result.returncode == 0 else None


def check_host(name, host, magic_dns_suffix, current_host):
    hostname = host["hostname"]
    row = {"name": name, "system": host["system"], "status": "unavailable"}
    health_command = ["/bin/sh", "-c", HEALTH_PROBE, "fleet-status", host["system"]]
    if current_host in (name.lower(), hostname.split(".")[0].lower()):
        return dict(row, status="local", **health_report(probe(health_command)))

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
            shlex.join(health_command),
        ]
        output = probe(command)
        if output is not None:
            return dict(
                row,
                status="reachable",
                route=route,
                address=address,
                **health_report(output),
            )
    return dict(row, **health_report(None))


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
        description="Report fleet system health, SSH reachability, and configured Nix caches.",
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
            for key in (
                "active_system",
                "active_revision",
                "needs_reboot",
                "failed_units",
                "snapraid",
                "disk_health",
            ):
                value = host[key]
                if key == "failed_units" and isinstance(value, list):
                    value = ", ".join(value) or "none"
                elif not isinstance(value, str):
                    value = json.dumps(value, ensure_ascii=True)
                print(f"  {key.replace('_', ' ')}: {value}")
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
