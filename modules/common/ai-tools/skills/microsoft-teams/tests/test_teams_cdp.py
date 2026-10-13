from __future__ import annotations

import json
import os
import re
import shutil
import socket
import subprocess
import tempfile
import threading
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import ClassVar

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "teams_cdp.mjs"
NODE = shutil.which("node")


def run(*args: str, port: int | None = None) -> subprocess.CompletedProcess[str]:
    env = dict(os.environ)
    if port is not None:
        env["CDP_PORT"] = str(port)
    return subprocess.run(
        [NODE or "node", str(SCRIPT), *args],
        env=env,
        capture_output=True,
        text=True,
        timeout=30,
        check=False,
    )


def free_port() -> int:
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


class FakeEndpoint(BaseHTTPRequestHandler):
    targets: ClassVar[list[dict[str, str]]] = [
        {
            "type": "page",
            "url": "https://example.com/",
            "webSocketDebuggerUrl": "ws://127.0.0.1:1/x",
        },
        {
            "type": "iframe",
            "url": "https://login.example.com/cb?code=secret#access_token=secret",
            "webSocketDebuggerUrl": "ws://127.0.0.1:1/y",
        },
    ]

    def do_GET(self) -> None:
        if self.path != "/json/list":
            self.send_error(404)
            return
        body = json.dumps(self.targets).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format: str, *args: object) -> None:
        pass


class PageSerializationTests(unittest.TestCase):
    def test_page_code_references_only_serialized_names(self) -> None:
        # Page and frame functions run inside Teams as source text, so any
        # top-level name they use must be serialized through PAGE_LIB.
        source = SCRIPT.read_text(encoding="utf-8")
        bodies = {
            m.group(1): m.group(0)
            for m in re.finditer(
                r"^(?:async )?function (\w+)\(.*?^}$", source, re.MULTILINE | re.DOTALL
            )
        }
        top_level = set(bodies) | set(
            re.findall(r"^(?:const|let|class) (\w+)", source, re.MULTILINE)
        )
        lib_match = re.search(r"const PAGE_LIB = \[(.*?)\]", source, re.DOTALL)
        assert lib_match is not None
        page_lib = set(re.findall(r"\w+", lib_match.group(1)))
        in_page = page_lib | {
            name for name in bodies if name.startswith(("page", "frame"))
        }
        for name in sorted(in_page):
            # Drop strings and comments, then match bare identifiers that are
            # neither property accesses nor object keys.
            code = re.sub(r"`[^`]*`|'[^'\n]*'|\"[^\"\n]*\"", '""', bodies[name])
            code = re.sub(r"//[^\n]*", "", code)
            used = set(re.findall(r"(?<![.\w$])([A-Za-z_$][\w$]*)\b(?!\s*:)", code))
            for ref in sorted((used & top_level) - page_lib - {name}):
                with self.subTest(function=name, references=ref):
                    self.fail(f"{name} uses {ref}, which PAGE_LIB does not serialize")


@unittest.skipUnless(NODE, "requires node")
class TeamsCdpCliTests(unittest.TestCase):
    def test_usage_errors_exit_2(self) -> None:
        cases = [
            (),
            ("bogus",),
            ("read", "--bogus"),
            ("read", "--max-chars", "0"),
            ("search",),
            ("search", "q", "--in"),
            ("search", "q", "--team", "Team A"),
            ("sp-list", "relative/site"),
            ("sp-download", "out"),
            ("eval",),
            ("cache-list", "extra"),
            ("cache-list", "--kind", "bogus"),
            ("cache-read",),
            ("cache-read", "x", "--limit", "5001"),
            ("cache-read", "x", "--since", "not-a-date"),
        ]
        for args in cases:
            with self.subTest(args=args):
                self.assertEqual(run(*args).returncode, 2)

    def test_sp_download_rejects_traversal_before_connecting(self) -> None:
        result = run("sp-download", "out", "/teams/site/../other", port=free_port())
        self.assertEqual(result.returncode, 2)
        self.assertIn('without ".."', result.stderr)

    def test_sp_download_refuses_overwrite_before_connecting(self) -> None:
        with tempfile.TemporaryDirectory() as out:
            existing = Path(out, "teams/site/Shared Documents/a.docx")
            existing.parent.mkdir(parents=True)
            existing.write_text("keep")
            result = run(
                "sp-download",
                out,
                "/teams/site/Shared Documents/a.docx",
                port=free_port(),
            )
            self.assertEqual(result.returncode, 2)
            self.assertIn("--force", result.stderr)
            self.assertEqual(existing.read_text(), "keep")

    def test_sp_download_creates_private_output_dir(self) -> None:
        with tempfile.TemporaryDirectory() as parent:
            out = Path(parent, "export")
            result = run(
                "sp-download", str(out), "/teams/site/a.docx", port=free_port()
            )
            self.assertEqual(result.returncode, 3)
            self.assertEqual(out.stat().st_mode & 0o777, 0o700)

    def test_missing_websocket_is_not_reported_as_missing_endpoint(self) -> None:
        # Exit 3 sends agents to the Teams launch steps, which a too-old Node
        # cannot fix.
        result = subprocess.run(
            [NODE or "node", "--no-experimental-websocket", str(SCRIPT), "status"],
            env={**os.environ, "CDP_PORT": str(free_port())},
            capture_output=True,
            text=True,
            timeout=30,
            check=False,
        )
        self.assertEqual(result.returncode, 1)
        self.assertIn("Node 22", result.stderr)

    def test_missing_endpoint_exits_3(self) -> None:
        result = run("status", port=free_port())
        self.assertEqual(result.returncode, 3)
        self.assertIn("no CDP endpoint", result.stderr)

    def test_endpoint_without_teams_page_exits_3(self) -> None:
        server = ThreadingHTTPServer(("127.0.0.1", 0), FakeEndpoint)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            port = server.server_address[1]
            status = run("status", port=port)
            self.assertEqual(status.returncode, 3)
            report = json.loads(status.stdout)
            self.assertIsNone(report["teamsPage"])
            self.assertEqual(
                report["frames"],
                [
                    {"type": "page", "url": "https://example.com/"},
                    {"type": "iframe", "url": "https://login.example.com/cb"},
                ],
            )
            self.assertNotIn("secret", status.stdout)

            read = run("read", port=port)
            self.assertEqual(read.returncode, 3)
            self.assertIn("no page target", read.stderr)
        finally:
            server.shutdown()
            server.server_close()


if __name__ == "__main__":
    unittest.main()
