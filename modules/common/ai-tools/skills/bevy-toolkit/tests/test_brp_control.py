#!/usr/bin/env python3

from __future__ import annotations

import json
import subprocess
import tempfile
import threading
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import ClassVar

SCRIPT = Path(__file__).parents[1] / "scripts/brp-control.py"


class BrpHandler(BaseHTTPRequestHandler):
    root_enabled = False
    invalid_response_method: str | None = None
    invalid_version_method: str | None = None
    mismatched_id_method: str | None = None
    rpc_error_method: str | None = None
    screenshot_writes = True
    requests: ClassVar[list[tuple[str, str, object]]] = []

    def log_message(self, _format: str, *args: object) -> None:
        pass

    def do_POST(self) -> None:
        handler = type(self)
        if self.path == "/" and not handler.root_enabled:
            self.send_error(404)
            return
        length = int(self.headers["Content-Length"])
        request = json.loads(self.rfile.read(length))
        method = request["method"]
        params = request["params"]
        handler.requests.append((self.path, method, params))

        if self.path == "/" and method == handler.invalid_response_method:
            body = b"not-json"
            self.send_response(200)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        if method == handler.rpc_error_method:
            body = json.dumps(
                {
                    "jsonrpc": "2.0",
                    "id": request["id"],
                    "error": {"code": -32000, "message": "expected failure"},
                }
            ).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        if method == "world.list_resources":
            result: object = ["example::Resource"]
        elif method == "world.get_resources":
            result = {"session": "expected"}
        elif method == "brp_extras/screenshot":
            if handler.screenshot_writes:
                Path(params["path"]).write_bytes(b"mock-png")
            result = {"saved": params["path"]}
        else:
            result = {"method": method, "params": params}
        version = "1.0" if method == handler.invalid_version_method else "2.0"
        response_id = (
            "wrong" if method == handler.mismatched_id_method else request["id"]
        )
        body = json.dumps(
            {"jsonrpc": version, "id": response_id, "result": result}
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

    def setUp(self) -> None:
        BrpHandler.root_enabled = False
        BrpHandler.invalid_response_method = None
        BrpHandler.invalid_version_method = None
        BrpHandler.mismatched_id_method = None
        BrpHandler.rpc_error_method = None
        BrpHandler.screenshot_writes = True
        BrpHandler.requests = []

    def invoke(
        self, *args: str, input_text: str | None = None
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(SCRIPT), "--url", self.url, *args],
            check=False,
            capture_output=True,
            input=input_text,
            text=True,
        )

    def run_script(
        self, *args: str, input_text: str | None = None
    ) -> dict[str, object]:
        result = self.invoke(*args, input_text=input_text)
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def test_status_falls_back_to_jsonrpc_path(self) -> None:
        result = self.run_script("status")
        self.assertEqual(result["status"], "success")
        self.assertEqual(result["mode"], "read-only")
        self.assertEqual(result["result"]["state"], "running_with_brp")
        self.assertEqual(result["result"]["resource_count"], 1)
        self.assertEqual(result["endpoint"], f"{self.url}/jsonrpc")

    def test_wait_timeout_uses_prerequisite_exit(self) -> None:
        result = subprocess.run(
            [
                str(SCRIPT),
                "--url",
                "http://127.0.0.1:1",
                "--timeout",
                "0.05",
                "wait",
                "--seconds",
                "0.1",
                "--interval",
                "0.01",
            ],
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 3)
        self.assertIn("BRP not ready after", result.stderr)

    def test_call_preserves_structured_params(self) -> None:
        result = self.run_script(
            "call",
            "world.query",
            '{"data":{},"filter":{"with":[]}}',
            "--read-only",
        )
        self.assertEqual(result["operation"], "call:world.query")
        self.assertEqual(result["result"]["method"], "world.query")
        self.assertEqual(result["result"]["params"]["data"], {})

    def test_call_accepts_stdin_json(self) -> None:
        result = self.run_script(
            "call", "world.query", "-", "--read-only", input_text='{"data":{}}'
        )
        self.assertEqual(result["result"]["params"], {"data": {}})

    def test_call_accepts_file_json(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "params.json"
            path.write_text('{"data":{"entity":42}}')
            result = self.run_script("call", "world.query", f"@{path}", "--read-only")
        self.assertEqual(result["result"]["params"], {"data": {"entity": 42}})

    def test_missing_json_file_is_clean_invocation_failure(self) -> None:
        result = self.invoke("call", "world.query", "@/missing/params.json")
        self.assertEqual(result.returncode, 2)
        self.assertIn("cannot read JSON input", result.stderr)
        self.assertNotIn("Traceback", result.stderr)

    def test_screenshot_reports_fresh_artifact(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "capture.png"
            result = self.run_script(
                "--allow-unguarded-mutation", "screenshot", str(path)
            )
            self.assertEqual(result["identity"]["guard"], "explicit-override")
            self.assertEqual(result["result"]["path"], str(path))
            self.assertEqual(result["result"]["size"], 8)
            self.assertEqual(path.read_bytes(), b"mock-png")

    def test_screenshot_refuses_existing_artifact_without_overwrite(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "capture.png"
            path.write_bytes(b"existing")
            result = self.invoke("--allow-unguarded-mutation", "screenshot", str(path))
        self.assertEqual(result.returncode, 4)
        self.assertIn("screenshot already exists", result.stderr)
        self.assertFalse(
            any(
                method == "brp_extras/screenshot"
                for _, method, _ in BrpHandler.requests
            )
        )

    def test_screenshot_overwrite_replaces_only_after_verification(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "capture.png"
            path.write_bytes(b"existing")
            self.run_script(
                "--allow-unguarded-mutation",
                "screenshot",
                str(path),
                "--overwrite",
            )
            self.assertEqual(path.read_bytes(), b"mock-png")

    def test_screenshot_failed_overwrite_preserves_existing_artifact(self) -> None:
        BrpHandler.screenshot_writes = False
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "capture.png"
            path.write_bytes(b"existing")
            result = self.invoke(
                "--allow-unguarded-mutation",
                "screenshot",
                str(path),
                "--overwrite",
                "--wait-seconds",
                "0.1",
            )
            self.assertEqual(path.read_bytes(), b"existing")
            self.assertEqual(list(path.parent.glob(".*.brp-*.tmp")), [])
        self.assertEqual(result.returncode, 5)
        self.assertIn("fresh nonempty screenshot not observed", result.stderr)

    def test_mutation_requires_identity_or_explicit_override(self) -> None:
        result = self.invoke("keys", "Space")
        self.assertEqual(result.returncode, 3)
        self.assertIn("mutation requires --identity-method", result.stderr)
        self.assertFalse(
            any(
                method == "brp_extras/send_keys" for _, method, _ in BrpHandler.requests
            )
        )

    def test_identity_mismatch_prevents_mutation(self) -> None:
        result = self.invoke(
            "--identity-method",
            "world.get_resources",
            "--identity-params",
            '{"resource":"example::SessionIdentity"}',
            "--identity-expected",
            '{"session":"wrong"}',
            "keys",
            "Space",
        )
        self.assertEqual(result.returncode, 5)
        self.assertIn("target identity mismatch", result.stderr)
        self.assertFalse(
            any(
                method == "brp_extras/send_keys" for _, method, _ in BrpHandler.requests
            )
        )

    def test_verified_identity_is_recorded_in_mutation_receipt(self) -> None:
        result = self.run_script(
            "--identity-method",
            "world.get_resources",
            "--identity-params",
            '{"resource":"example::SessionIdentity"}',
            "--identity-expected",
            '{"session":"expected"}',
            "keys",
            "Space",
            "--duration-ms",
            "500",
        )
        self.assertEqual(result["mode"], "mutation")
        self.assertEqual(result["identity"]["guard"], "identity")
        self.assertTrue(result["identity"]["verified"])
        self.assertEqual(
            result["result"]["params"], {"keys": ["Space"], "duration_ms": 500}
        )

    def test_unlisted_identity_method_is_rejected_before_request(self) -> None:
        result = self.invoke(
            "--identity-method",
            "example.identity",
            "--identity-expected",
            '{"session":"expected"}',
            "keys",
            "Space",
        )
        self.assertEqual(result.returncode, 3)
        self.assertIn("identity method must be an allowlisted", result.stderr)
        self.assertFalse(
            any(method == "example.identity" for _, method, _ in BrpHandler.requests)
        )

    def test_unlisted_method_cannot_claim_read_only(self) -> None:
        result = self.invoke(
            "call", "world.despawn_entity", '{"entities":[1]}', "--read-only"
        )
        self.assertEqual(result.returncode, 3)
        self.assertIn("--read-only is not permitted", result.stderr)
        self.assertEqual(BrpHandler.requests, [])

    def test_mutation_is_not_retried_after_ambiguous_response(self) -> None:
        BrpHandler.root_enabled = True
        BrpHandler.invalid_response_method = "example.mutate"
        result = self.invoke(
            "--allow-unguarded-mutation", "call", "example.mutate", "{}"
        )
        self.assertEqual(result.returncode, 4)
        mutation_requests = [
            request for request in BrpHandler.requests if request[1] == "example.mutate"
        ]
        self.assertEqual(mutation_requests, [("/", "example.mutate", {})])

    def test_json_rpc_error_uses_execution_failure_exit(self) -> None:
        BrpHandler.rpc_error_method = "world.get_components"
        result = self.invoke("call", "world.get_components", "{}", "--read-only")
        self.assertEqual(result.returncode, 4)
        self.assertIn("JSON-RPC -32000: expected failure", result.stderr)

    def test_mismatched_response_id_is_rejected(self) -> None:
        BrpHandler.mismatched_id_method = "world.query"
        result = self.invoke("call", "world.query", "{}", "--read-only")
        self.assertEqual(result.returncode, 4)
        self.assertIn("response ID does not match request", result.stderr)

    def test_invalid_json_rpc_version_is_rejected(self) -> None:
        BrpHandler.invalid_version_method = "world.query"
        result = self.invoke("call", "world.query", "{}", "--read-only")
        self.assertEqual(result.returncode, 4)
        self.assertIn("invalid JSON-RPC version", result.stderr)

    def test_nonfinite_timeout_is_clean_invocation_failure(self) -> None:
        result = self.invoke("--timeout", "nan", "status")
        self.assertEqual(result.returncode, 2)
        self.assertIn("value must be finite", result.stderr)

    def test_nonfinite_mouse_coordinate_is_clean_invocation_failure(self) -> None:
        result = self.invoke(
            "--allow-unguarded-mutation", "mouse-move", "--position", "nan", "1"
        )
        self.assertEqual(result.returncode, 2)
        self.assertIn("value must be finite", result.stderr)
        self.assertEqual(BrpHandler.requests, [])

    def test_url_query_is_rejected_without_request(self) -> None:
        result = subprocess.run(
            [str(SCRIPT), "--url", f"{self.url}?target=wrong", "status"],
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 4)
        self.assertIn("invalid BRP URL", result.stderr)
        self.assertEqual(BrpHandler.requests, [])


if __name__ == "__main__":
    unittest.main()
