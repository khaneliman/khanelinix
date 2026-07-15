#!/usr/bin/env python3

from __future__ import annotations

import json
import subprocess
import tempfile
import threading
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

SCRIPT = Path(__file__).parents[1] / "scripts/brp-control.py"


class BrpHandler(BaseHTTPRequestHandler):
    def log_message(self, _format: str, *args: object) -> None:
        pass

    def do_POST(self) -> None:
        if self.path == "/":
            self.send_error(404)
            return
        length = int(self.headers["Content-Length"])
        request = json.loads(self.rfile.read(length))
        method = request["method"]
        params = request["params"]
        if method == "world.list_resources":
            result: object = ["example::Resource"]
        elif method == "brp_extras/screenshot":
            Path(params["path"]).write_bytes(b"mock-png")
            result = {"saved": params["path"]}
        else:
            result = {"method": method, "params": params}
        body = json.dumps(
            {"jsonrpc": "2.0", "id": request["id"], "result": result}
        ).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


class BrpControlTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.server = ThreadingHTTPServer(("127.0.0.1", 0), BrpHandler)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
        cls.url = f"http://127.0.0.1:{cls.server.server_port}"

    @classmethod
    def tearDownClass(cls) -> None:
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join()

    def run_script(self, *args: str) -> dict[str, object]:
        result = subprocess.run(
            [str(SCRIPT), "--url", self.url, *args],
            check=True,
            capture_output=True,
            text=True,
        )
        return json.loads(result.stdout)

    def test_status_falls_back_to_jsonrpc_path(self) -> None:
        result = self.run_script("status")
        self.assertEqual(result["status"], "running_with_brp")
        self.assertEqual(result["resource_count"], 1)
        self.assertEqual(result["endpoint"], f"{self.url}/jsonrpc")

    def test_call_preserves_structured_params(self) -> None:
        result = self.run_script(
            "call", "world.query", '{"data":{},"filter":{"with":[]}}'
        )
        self.assertEqual(result["method"], "world.query")
        self.assertEqual(result["params"]["data"], {})

    def test_screenshot_reports_fresh_artifact(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "capture.png"
            result = self.run_script("screenshot", str(path))
            self.assertEqual(result["path"], str(path))
            self.assertEqual(result["size"], 8)
            self.assertEqual(path.read_bytes(), b"mock-png")


if __name__ == "__main__":
    unittest.main()
