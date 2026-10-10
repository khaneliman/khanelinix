import importlib.util
import io
import subprocess
import unittest
from contextlib import redirect_stderr
from pathlib import Path
from unittest.mock import Mock

spec = importlib.util.spec_from_file_location(
    "repair", Path(__file__).with_name("repair-connection.py")
)
repair = importlib.util.module_from_spec(spec)
spec.loader.exec_module(repair)


class RecoveryTests(unittest.TestCase):
    def test_reconnection_uses_the_exact_new_sessions_persisted_connection_record(self):
        fresh = {"sessionId": "new", "connected": False, "lastConnectedAt": None}
        unrelated = {"sessionId": "old", "lastConnectedAt": "2026-10-10T04:00:00Z"}
        self.assertFalse(repair.session_reconnected([fresh, unrelated], "new"))
        fresh["lastConnectedAt"] = "2026-10-10T04:10:00Z"
        self.assertTrue(repair.session_reconnected([fresh, unrelated], "new"))

    def test_old_and_new_product_names_can_read_both_keyring_identities(self):
        for name in ("T3 Code (Alpha)", "T3 Code Alpha"):
            names = repair.keyring_names(name)
            self.assertEqual(names[0], name)
            self.assertEqual(set(names), {"T3 Code (Alpha)", "T3 Code Alpha"})

    def test_ambiguous_write_is_revocable_only_when_confirmed_absent(self):
        for installed in (True, False):
            self.assertIs(
                repair.recover_installation(
                    Mock(return_value={"installed": installed}), "T3", "secret"
                ),
                installed,
            )
        output = io.StringIO()
        with redirect_stderr(output):
            self.assertIsNone(
                repair.recover_installation(
                    Mock(side_effect=subprocess.TimeoutExpired("native", 20)),
                    "T3",
                    "secret",
                )
            )
        self.assertNotIn("secret", output.getvalue())

    def test_credentials_are_not_forwarded_on_redirect(self):
        with self.assertRaises(RuntimeError):
            repair.NoRedirects().redirect_request(
                None, None, 302, "", {}, "https://other.example"
            )

    def test_native_issue_scopes_exclude_access_administration(self):
        self.assertIn("filesystem:read", repair.CLIENT_SCOPES)
        self.assertFalse(
            {"access:read", "access:write", "relay:write"}.intersection(
                repair.CLIENT_SCOPES
            )
        )


if __name__ == "__main__":
    unittest.main()
