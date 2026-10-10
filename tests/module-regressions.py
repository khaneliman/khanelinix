"""Focused module checks without host or flake evaluation.

Run: python3 tests/module-regressions.py /path/to/locked/nixpkgs ignored-scratch-dir
"""

import argparse
import json
import pathlib
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("nixpkgs", type=pathlib.Path)
parser.add_argument("scratch", type=pathlib.Path)
args = parser.parse_args()
root = pathlib.Path(__file__).resolve().parent.parent
args.scratch.mkdir(parents=True, exist_ok=True)
expression = (
    "import (builtins.toPath "
    + json.dumps(str(root / "tests/module-regressions.nix"))
    + ") { nixpkgs = builtins.toPath "
    + json.dumps(str(args.nixpkgs.resolve()))
    + "; }"
)
result = json.loads(
    subprocess.check_output(
        [
            "nix",
            "eval",
            "--impure",
            "--json",
            "--expr",
            expression,
        ],
        text=True,
    )
)
assert len(result["credentials"]) == 64 and all(result["credentials"])
assert len(result["suite"]) == 10 and all(result["suite"])
assert result["wsl"]
for mode, rendered in result["ssh"].items():
    config = args.scratch / (mode + "-ssh.conf")
    config.write_text(rendered["extraConfig"])
    cases = {
        "linux": ("linux.local", "linux-user", "yes", "10", "2222"),
        "mac": ("mac.local", "mac-user", "yes", "10", "22"),
        "custom": ("custom.example", "custom-user", "yes", "17", "22"),
        "unmatched": ("unmatched", None, "no", "5", "22"),
        "local": ("local", None, "no", "5", "22"),
    }
    if mode == "enabled":
        cases["linux-ts"] = ("linux.fleet.example", "linux-user", "yes", "10", "2222")
        cases["mac-ts"] = ("mac.fleet.example", "mac-user", "yes", "10", "22")
    else:
        cases["linux-ts"] = ("linux-ts", None, "no", "5", "22")
    for host, (hostname, user, forwarding, timeout, port) in cases.items():
        output = subprocess.check_output(
            ["ssh", "-G", "-F", str(config), host], text=True
        )
        effective = dict(line.split(" ", 1) for line in output.splitlines())
        expected = {
            "hostname": hostname,
            "forwardagent": forwarding,
            "connecttimeout": timeout,
            "port": port,
            "addkeystoagent": "true",
            "serveraliveinterval": "30",
            "serveralivecountmax": "2",
            "streamlocalbindunlink": "yes",
        }
        if user:
            expected["user"] = user
        if host in ("linux", "mac", "linux-ts", "mac-ts") and (
            mode == "enabled" or not host.endswith("-ts")
        ):
            expected["addressfamily"] = "inet"
        for name, value in expected.items():
            assert effective[name] == value, (mode, host, name, effective[name], value)
    assert "RemoteForward /run/user/1000/gnupg/S.gpg-agent " in config.read_text()
    assert (
        rendered["knownHosts"]["github-ed25519"]["publicKey"]
        == "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl"
    )
print(
    "PASS: 64 credential combinations, 10 suite baselines and overrides, WSL gate, 13 SSH resolutions"
)
