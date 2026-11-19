import contextlib
import io
import json
import os
import subprocess
import tempfile
import threading
import unittest
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from unittest.mock import patch

import fleet_status as fleet

HOST = {
    "hostname": "example.local",
    "system": "nixos",
    "tailscaleIp": "100.64.0.10",
    "username": "tester",
}


class FleetStatusTests(unittest.TestCase):
    def test_ssh_probes_fall_back_without_enabling_forwarding_or_host_key_writes(self):
        with patch.object(fleet, "probe", side_effect=[None, None, ""]) as probe:
            row = fleet.check_host("example", HOST, "example.ts.net", "workstation")
        self.assertEqual(row["status"], "reachable")
        self.assertEqual(row["route"], "tailnet-ip")
        commands = [call.args[0] for call in probe.call_args_list]
        self.assertEqual(
            [
                next(arg for arg in cmd if arg.startswith("-oHostName="))
                for cmd in commands
            ],
            [
                "-oHostName=example.local",
                "-oHostName=example.example.ts.net",
                "-oHostName=100.64.0.10",
            ],
        )
        self.assertEqual(
            [cmd[-2:] for cmd in commands],
            [["example", "true"], ["example-ts", "true"], ["example", "true"]],
        )
        for cmd in commands:
            self.assertIn("-oStrictHostKeyChecking=yes", cmd)
            self.assertIn("-oUpdateHostKeys=no", cmd)
            self.assertIn("-oClearAllForwardings=yes", cmd)
            self.assertIn("-oControlPath=none", cmd)

    def test_host_without_tailscale_ip_only_tries_names(self):
        host = {key: value for key, value in HOST.items() if key != "tailscaleIp"}
        with patch.object(fleet, "probe", return_value=None) as probe:
            row = fleet.check_host("example", host, "example.ts.net", "workstation")
        self.assertEqual(row["status"], "unavailable")
        self.assertEqual(probe.call_count, 2)

    def test_probe_timeouts_are_bounded(self):
        command = ["ssh", "example", "true"]
        with patch.object(
            fleet.subprocess, "run", side_effect=subprocess.TimeoutExpired(command, 5)
        ) as runner:
            self.assertIsNone(fleet.probe(command))
        self.assertEqual(runner.call_args.kwargs["timeout"], 5)

    def test_local_http_cache_checks_metadata_not_just_http_status(self):
        class CacheHandler(BaseHTTPRequestHandler):
            def do_GET(self):
                responses = {
                    "/cache/nix-cache-info": b"StoreDir: /nix/store\nPriority: 50\n",
                    "/not-a-cache/nix-cache-info": b"<html>not a cache</html>",
                }
                body = responses.get(self.path)
                self.send_response(200 if body else 404)
                self.end_headers()
                if body:
                    self.wfile.write(body)

            def log_message(self, *_):
                pass

        with HTTPServer(("127.0.0.1", 0), CacheHandler) as server:
            thread = threading.Thread(target=server.serve_forever)
            thread.start()
            try:
                base = f"http://127.0.0.1:{server.server_port}"
                with patch.dict(os.environ, {"no_proxy": "127.0.0.1"}):
                    self.assertEqual(
                        fleet.check_cache(f"{base}/cache/?priority=51"),
                        {"cache": f"{base}/cache/", "status": "reachable"},
                    )
                    self.assertEqual(
                        fleet.check_cache(f"{base}/not-a-cache")["status"],
                        "invalid metadata",
                    )
                    self.assertEqual(
                        fleet.check_cache(f"{base}/missing")["status"], "unavailable"
                    )
            finally:
                server.shutdown()
                thread.join()

    def test_cache_credentials_are_not_used_or_reported(self):
        with patch.object(fleet, "probe") as probe:
            row = fleet.check_cache("https://user:password@cache.example/?token=secret")
        self.assertEqual(
            row,
            {
                "cache": "https://cache.example/",
                "status": "not checked (credentials configured)",
            },
        )
        probe.assert_not_called()

    def test_report_keeps_offline_hosts_and_caches_without_failing(self):
        cache = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
        cache.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=cache) as scratch:
            inventory = Path(scratch) / "inventory.json"
            inventory.write_text(
                json.dumps(
                    {
                        "hosts": {
                            "example": HOST,
                            "local": dict(HOST, hostname="local.local"),
                        },
                        "magicDnsSuffix": "example.ts.net",
                    }
                ),
                encoding="utf-8",
            )

            def probe(command):
                if command[0] == "nix":
                    return "https://cache.example"
                return None

            output = io.StringIO()
            with (
                patch.object(fleet, "probe", side_effect=probe),
                patch.object(fleet.socket, "gethostname", return_value="local.local"),
                contextlib.redirect_stdout(output),
            ):
                self.assertEqual(
                    fleet.main(["--inventory", str(inventory), "--json"]), 0
                )
            self.assertEqual(
                json.loads(output.getvalue()),
                {
                    "hosts": [
                        {"name": "example", "system": "nixos", "status": "unavailable"},
                        {"name": "local", "system": "nixos", "status": "local"},
                    ],
                    "caches": [
                        {"cache": "https://cache.example", "status": "unavailable"}
                    ],
                },
            )
