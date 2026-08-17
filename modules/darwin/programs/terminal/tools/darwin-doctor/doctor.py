"""Report drift in declarative macOS workstation state."""

import argparse
import json
import os
import plistlib
import shutil
import subprocess
from pathlib import Path
from typing import Any

FAILURE_STATES = {"mismatch", "unavailable"}


def command(
    arguments: list[str], timeout: int = 20
) -> subprocess.CompletedProcess[bytes]:
    try:
        return subprocess.run(
            arguments,
            check=False,
            capture_output=True,
            timeout=timeout,
        )
    except subprocess.TimeoutExpired:
        return subprocess.CompletedProcess(
            arguments,
            124,
            stdout=b"",
            stderr=f"timed out after {timeout} seconds".encode(),
        )
    except FileNotFoundError:
        return subprocess.CompletedProcess(
            arguments,
            127,
            stdout=b"",
            stderr=f"command is missing: {arguments[0]}".encode(),
        )


def detail(result: subprocess.CompletedProcess[bytes]) -> str:
    output = result.stdout or result.stderr
    return output.decode(errors="replace").strip()


def result(name: str, status: str, message: str) -> dict[str, str]:
    return {"name": name, "status": status, "detail": message}


def check_developer_directory(specification: dict[str, Any]) -> dict[str, str]:
    expected = specification["developerDirectory"]
    if not specification["enabled"] or expected is None:
        return result("developer-directory", "skipped", "not managed")
    current = command(["/usr/bin/xcode-select", "-p"])
    if current.returncode != 0:
        return result("developer-directory", "unavailable", detail(current))
    actual = detail(current)
    status = "pass" if actual == expected else "mismatch"
    return result("developer-directory", status, f"expected {expected}; found {actual}")


def check_devtools_security(specification: dict[str, Any]) -> dict[str, str]:
    expected = specification["devToolsSecurity"]
    if not specification["enabled"] or expected == "ignore":
        return result("devtools-security", "skipped", "not managed")
    current = command(["/usr/sbin/DevToolsSecurity", "-status"])
    output = detail(current).lower()
    if "disabled" in output:
        actual = "disabled"
    elif "enabled" in output:
        actual = "enabled"
    else:
        return result("devtools-security", "unavailable", output or "unknown state")
    status = "pass" if actual == expected else "mismatch"
    return result("devtools-security", status, f"expected {expected}; found {actual}")


def check_launch_agent(domain: str, label: str) -> dict[str, str]:
    target = f"{domain}/{os.getuid()}/{label}"
    current = command(["/bin/launchctl", "print", target])
    status = "pass" if current.returncode == 0 else "unavailable"
    message = "loaded" if current.returncode == 0 else detail(current)
    return result(f"launch-agent:{label}", status, message)


def check_container(specification: dict[str, Any]) -> list[dict[str, str]]:
    backend = specification["containerBackend"]
    if not specification["enabled"] or backend == "none":
        return [result("container-backend", "skipped", "disabled")]
    checks = []
    if backend == "colima":
        colima = shutil.which("colima")
        if colima is None:
            checks.append(result("colima", "unavailable", "colima command is missing"))
        else:
            current = command([colima, "status"])
            checks.append(
                result(
                    "colima",
                    "pass" if current.returncode == 0 else "unavailable",
                    detail(current),
                )
            )
    else:
        exists = Path("/Applications/Docker.app").exists()
        checks.append(
            result(
                "docker-desktop",
                "pass" if exists else "unavailable",
                "installed" if exists else "/Applications/Docker.app is missing",
            )
        )
    docker = shutil.which("docker")
    if docker is None:
        checks.append(
            result("docker-engine", "unavailable", "docker command is missing")
        )
    else:
        current = command([docker, "info"], timeout=30)
        checks.append(
            result(
                "docker-engine",
                "pass" if current.returncode == 0 else "unavailable",
                "reachable" if current.returncode == 0 else detail(current),
            )
        )
    return checks


def check_homebrew(specification: dict[str, Any]) -> dict[str, str]:
    if not specification["enabled"]:
        return result("homebrew-bundle", "skipped", "disabled")
    brew = shutil.which("brew")
    if brew is None:
        brew = next(
            (
                candidate
                for candidate in ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
                if Path(candidate).exists()
            ),
            None,
        )
    if brew is None:
        return result("homebrew-bundle", "unavailable", "brew command is missing")
    current = command(
        [brew, "bundle", "check", "--file", specification["brewfile"]], timeout=60
    )
    status = "pass" if current.returncode == 0 else "mismatch"
    return result(
        "homebrew-bundle", status, detail(current) or "dependencies satisfied"
    )


def export_domain(domain: str) -> dict[str, Any] | None:
    current = command(["/usr/bin/defaults", "export", domain, "-"])
    if current.returncode != 0:
        return None
    value = plistlib.loads(current.stdout)
    return value if isinstance(value, dict) else None


def check_preferences(preferences: list[dict[str, Any]]) -> list[dict[str, str]]:
    domains: dict[str, dict[str, Any] | None] = {}
    checks = []
    for preference in preferences:
        domain = preference["domain"]
        key = preference["key"]
        if domain not in domains:
            domains[domain] = export_domain(domain)
        values = domains[domain]
        if values is None or key not in values:
            checks.append(
                result(f"preference:{domain}:{key}", "mismatch", "key is missing")
            )
            continue
        expected = preference["value"]
        actual = values[key]
        status = "pass" if actual == expected else "mismatch"
        checks.append(
            result(
                f"preference:{domain}:{key}",
                status,
                f"expected {expected!r}; found {actual!r}",
            )
        )
    return checks


def check_time_machine(specification: dict[str, Any]) -> list[dict[str, str]]:
    if not specification["enabled"]:
        return [result("time-machine", "skipped", "disabled")]
    checks = []
    status = command(["/usr/bin/tmutil", "status"])
    checks.append(
        result(
            "time-machine",
            "pass" if status.returncode == 0 else "unavailable",
            detail(status),
        )
    )
    expected_destination = specification["expectedDestination"]
    if expected_destination is None:
        checks.append(result("time-machine-destination", "skipped", "no expectation"))
    else:
        destination = command(["/usr/bin/tmutil", "destinationinfo"])
        output = detail(destination)
        matches = destination.returncode == 0 and expected_destination in output
        checks.append(
            result(
                "time-machine-destination",
                "pass" if matches else "mismatch",
                output or "no destination",
            )
        )
    for path in specification["exclusions"]:
        if not Path(path).exists():
            checks.append(
                result(f"time-machine-exclusion:{path}", "skipped", "path is missing")
            )
            continue
        excluded = command(["/usr/bin/tmutil", "isexcluded", path])
        output = detail(excluded)
        matches = excluded.returncode == 0 and output.startswith("[Excluded]")
        checks.append(
            result(
                f"time-machine-exclusion:{path}",
                "pass" if matches else "mismatch",
                output or "state unavailable",
            )
        )
    return checks


def run_checks(specification: dict[str, Any]) -> list[dict[str, str]]:
    checks = [
        check_developer_directory(specification["development"]),
        check_devtools_security(specification["development"]),
    ]
    checks.extend(check_container(specification["development"]))
    checks.append(check_homebrew(specification["homebrew"]))
    checks.extend(check_preferences(specification["preferences"]))
    checks.extend(check_time_machine(specification["timeMachine"]))
    for agent in specification["launchAgents"]:
        checks.append(check_launch_agent(agent["domain"], agent["Label"]))
    return checks


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--specification",
        type=Path,
        default=Path("/etc/khanelinix/darwin-doctor.json"),
    )
    parser.add_argument("--json", action="store_true")
    return parser.parse_args()


def main() -> None:
    arguments = parse_arguments()
    with arguments.specification.open(encoding="utf-8") as stream:
        specification = json.load(stream)
    checks = run_checks(specification)
    if arguments.json:
        print(json.dumps(checks, indent=2))
    else:
        width = max(len(check["status"]) for check in checks)
        for check in checks:
            print(f"{check['status']:<{width}}  {check['name']}: {check['detail']}")
    if any(check["status"] in FAILURE_STATES for check in checks):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
