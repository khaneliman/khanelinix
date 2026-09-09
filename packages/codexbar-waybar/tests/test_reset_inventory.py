import base64
import copy
import http.client
import importlib.util
import io
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock, patch

spec = importlib.util.spec_from_file_location(
    "reset_inventory",
    os.environ.get(
        "RESET_INVENTORY_HELPER",
        Path(__file__).resolve().parents[1] / "reset-inventory.py",
    ),
)
inventory = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = inventory
spec.loader.exec_module(inventory)


def auth(email="user@example.test", account="workspace-a"):
    claims = (
        base64.urlsafe_b64encode(json.dumps({"email": email}).encode())
        .decode()
        .rstrip("=")
    )
    return json.dumps(
        {
            "tokens": {
                "id_token": f"header.{claims}.signature",
                "access_token": "secret-token",
                "account_id": account,
            }
        }
    )


class ResetInventoryTests(unittest.TestCase):
    def setUp(self):
        self.owner = inventory.decode_credentials(auth())
        self.entries = [
            {"provider": "codex", "usage": {"accountEmail": self.owner.email}}
        ]
        self.snapshot = {
            "availableCount": 1,
            "credits": [{"status": "available", "expires_at": None}],
        }

    def test_matching_account_receives_inventory(self):
        fetch = Mock(return_value=self.snapshot)
        result = inventory.enrich(self.entries, self.owner, self.owner, fetch)
        self.assertEqual(result[0]["usage"]["codexResetCredits"], self.snapshot)
        self.assertNotIn("codexResetCreditsUnavailable", result[0]["usage"])
        fetch.assert_called_once_with(self.owner)

    def test_workspace_switch_does_not_fetch_or_attach(self):
        other = inventory.decode_credentials(auth(account="workspace-b"))
        fetch = Mock()
        inventory.enrich(self.entries, self.owner, other, fetch)
        fetch.assert_not_called()
        self.assertTrue(self.entries[0]["usage"]["codexResetCreditsUnavailable"])

    def test_mismatched_or_missing_email_does_not_fetch(self):
        for email in (None, "other@example.test"):
            with self.subTest(email=email):
                entries = [{"provider": "codex", "usage": {"accountEmail": email}}]
                fetch = Mock()
                inventory.enrich(entries, self.owner, self.owner, fetch)
                fetch.assert_not_called()

    def test_multi_account_output_is_not_enriched(self):
        entries = self.entries + copy.deepcopy(self.entries)
        fetch = Mock()
        inventory.enrich(entries, self.owner, self.owner, fetch)
        fetch.assert_not_called()

    def test_token_refresh_preserves_owner(self):
        refreshed = inventory.Credentials(
            self.owner.account, self.owner.email, "new-token"
        )
        fetch = Mock(return_value=self.snapshot)
        inventory.enrich(self.entries, self.owner, refreshed, fetch)
        fetch.assert_called_once_with(refreshed)

    def test_network_failure_is_unknown_not_zero(self):
        inventory.enrich(
            self.entries, self.owner, self.owner, Mock(side_effect=OSError())
        )
        self.assertNotIn("codexResetCredits", self.entries[0]["usage"])
        self.assertTrue(self.entries[0]["usage"]["codexResetCreditsUnavailable"])

    def test_http_protocol_failure_preserves_usage(self):
        response = Mock()
        response.read.side_effect = http.client.IncompleteRead(b"partial", 10)
        opener = Mock()
        opener.open.return_value.__enter__ = Mock(return_value=response)
        opener.open.return_value.__exit__ = Mock(return_value=False)
        with patch.object(
            inventory.urllib.request, "build_opener", return_value=opener
        ):
            inventory.enrich(
                self.entries, self.owner, self.owner, inventory.fetch_inventory
            )
        self.assertNotIn("codexResetCredits", self.entries[0]["usage"])
        self.assertTrue(self.entries[0]["usage"]["codexResetCreditsUnavailable"])

    def test_slow_inventory_worker_cannot_discard_successful_cli_output(self):
        output = io.StringIO()
        with tempfile.TemporaryDirectory() as directory:
            worker = Path(directory, "slow-inventory.py")
            worker.write_text("import sys,time; sys.stdin.read(); time.sleep(10)\n")
            command = [
                "helper",
                sys.executable,
                "-c",
                f"print({json.dumps(self.entries)!r})",
            ]
            with (
                patch.object(inventory, "__file__", str(worker)),
                patch.object(inventory, "INVENTORY_TIMEOUT", 0.05),
                patch.object(inventory, "read_credentials", return_value=self.owner),
                patch.object(inventory.sys, "argv", command),
                patch.object(inventory.sys, "stdout", output),
            ):
                self.assertEqual(inventory.main(), 0)
        usage = json.loads(output.getvalue())[0]["usage"]
        self.assertEqual(usage["accountEmail"], self.owner.email)
        self.assertTrue(usage["codexResetCreditsUnavailable"])

    def test_inventory_subprocess_receives_credentials_only_through_stdin(self):
        with patch.object(
            inventory.subprocess,
            "run",
            return_value=Mock(stdout=json.dumps(self.snapshot)),
        ) as run:
            inventory.fetch_inventory_bounded(self.owner)
        self.assertNotIn("secret-token", str(run.call_args.args))
        self.assertEqual(
            json.loads(run.call_args.kwargs["input"])["access_token"], "secret-token"
        )
        self.assertEqual(run.call_args.kwargs["timeout"], 5)

    def test_existing_inventory_and_other_providers_are_preserved(self):
        self.entries[0]["usage"]["codexResetCredits"] = self.snapshot
        self.entries.append(
            {"provider": "claude", "usage": {"primary": {"usedPercent": 55}}}
        )
        expected = copy.deepcopy(self.entries)
        fetch = Mock()
        inventory.enrich(self.entries, self.owner, self.owner, fetch)
        self.assertEqual(self.entries, expected)
        fetch.assert_not_called()

    def test_missing_auth_does_not_fetch(self):
        fetch = Mock()
        inventory.enrich(self.entries, None, None, fetch)
        fetch.assert_not_called()

    def test_file_auth_respects_configured_home(self):
        with (
            tempfile.TemporaryDirectory() as directory,
            patch.dict(os.environ, {"CODEX_HOME": directory}),
        ):
            Path(directory, "auth.json").write_text(auth())
            self.assertEqual(inventory.read_credentials(), self.owner)

    def test_keyring_uses_exact_codex_service_and_home_hash(self):
        with (
            tempfile.TemporaryDirectory() as directory,
            patch.dict(os.environ, {"CODEX_HOME": directory}),
        ):
            Path(directory, "config.toml").write_text(
                'cli_auth_credentials_store = "auto"\n'
            )
            with patch.object(
                inventory.subprocess,
                "run",
                return_value=Mock(returncode=0, stdout=auth()),
            ) as run:
                self.assertEqual(inventory.read_credentials(), self.owner)
                args = run.call_args.args[0]
                self.assertEqual(
                    args[1:5], ["lookup", "service", "Codex Auth", "username"]
                )
                expected = (
                    "cli|"
                    + inventory.hashlib.sha256(
                        str(Path(directory).resolve()).encode()
                    ).hexdigest()[:16]
                )
                self.assertEqual(args[5], expected)
                self.assertNotIn("secret-token", str(run.call_args))

    def test_keyring_timeout_falls_back_only_in_auto_mode(self):
        for mode in ("auto", "keyring"):
            with (
                self.subTest(mode=mode),
                tempfile.TemporaryDirectory() as directory,
                patch.dict(os.environ, {"CODEX_HOME": directory}),
            ):
                Path(directory, "auth.json").write_text(auth())
                Path(directory, "config.toml").write_text(
                    f'cli_auth_credentials_store = "{mode}"\n'
                )
                with patch.object(
                    inventory.subprocess,
                    "run",
                    side_effect=subprocess.TimeoutExpired("lookup", 2),
                ):
                    self.assertEqual(
                        inventory.read_credentials(),
                        self.owner if mode == "auto" else None,
                    )

    def test_fetch_is_get_only_and_strips_nonpresentation_fields(self):
        response = Mock()
        response.read.return_value = json.dumps(
            {
                "available_count": 1,
                "credits": [
                    {
                        "id": "private-credit-id",
                        "status": "available",
                        "expires_at": "2026-10-05T04:18:34.696769Z",
                    }
                ],
            }
        ).encode()
        opener = Mock()
        opener.open.return_value.__enter__ = Mock(return_value=response)
        opener.open.return_value.__exit__ = Mock(return_value=False)
        with patch.object(
            inventory.urllib.request, "build_opener", return_value=opener
        ):
            result = inventory.fetch_inventory(self.owner)
        request = opener.open.call_args.args[0]
        self.assertEqual(request.get_method(), "GET")
        self.assertEqual(
            request.full_url,
            "https://chatgpt.com/backend-api/wham/rate-limit-reset-credits",
        )
        self.assertEqual(request.get_header("Chatgpt-account-id"), self.owner.account)
        self.assertEqual(result["availableCount"], 1)
        self.assertNotIn("private-credit-id", json.dumps(result))
        self.assertNotIn("secret-token", json.dumps(result))

    def test_redirect_is_not_followed(self):
        self.assertIsNone(
            inventory.NoRedirect().redirect_request(
                None, None, 302, "", {}, "https://other.test"
            )
        )

    def test_cli_wrapper_preserves_usage_and_exit_status_without_credentials(self):
        with tempfile.TemporaryDirectory() as directory:
            result = subprocess.run(
                [
                    sys.executable,
                    inventory.__file__,
                    sys.executable,
                    "-c",
                    'import json,sys; print(json.dumps([{"provider":"codex","usage":{"primary":{"usedPercent":42}}}])); sys.exit(3)',
                ],
                capture_output=True,
                text=True,
                env={**os.environ, "CODEX_HOME": directory},
                check=False,
            )
        self.assertEqual(result.returncode, 3)
        usage = json.loads(result.stdout)[0]["usage"]
        self.assertEqual(usage["primary"]["usedPercent"], 42)
        self.assertTrue(usage["codexResetCreditsUnavailable"])
        self.assertEqual(result.stderr, "")

    def test_credentials_repr_does_not_expose_token(self):
        self.assertNotIn("secret-token", repr(self.owner))


if __name__ == "__main__":
    unittest.main()
