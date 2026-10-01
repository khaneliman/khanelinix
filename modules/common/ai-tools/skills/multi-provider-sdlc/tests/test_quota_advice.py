import importlib.util
import io
import json
import subprocess
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path
from unittest import mock

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "quota-advice.py"
SPEC = importlib.util.spec_from_file_location("quota_advice", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
quota = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(quota)
NOW = datetime(2026, 10, 1, tzinfo=timezone.utc)


def snapshot(age=0, provider="codex"):
    return [
        {
            "provider": provider,
            "account": "private-account-id",
            "usage": {
                "updatedAt": (NOW - timedelta(seconds=age)).isoformat(),
                "primary": {
                    "usedPercent": 25,
                    "resetsAt": (NOW + timedelta(seconds=100)).isoformat(),
                },
                "secondary": {
                    "usedPercent": 60,
                    "resetsAt": (NOW + timedelta(days=1)).isoformat(),
                },
            },
            "pace": {
                "primary": {"willLastToReset": True},
                "secondary": {"willLastToReset": True},
            },
        }
    ]


class QuotaAdviceTests(unittest.TestCase):
    def summarize(self, data, **kwargs):
        return quota.summarize(data, "codex", now=NOW, **kwargs)

    def cli(self, *args, stdin="", error=None, stdout=""):
        with (
            mock.patch.object(quota.subprocess, "run", side_effect=error) as run,
            mock.patch.object(quota.sys, "stdin", io.StringIO(stdin)),
            mock.patch.object(quota.sys, "stdout", new_callable=io.StringIO) as output,
        ):
            run.return_value = subprocess.CompletedProcess(["codexbar"], 0, stdout)
            self.assertEqual(quota.main(["--provider", "codex", *args]), 0)
            return json.loads(output.getvalue()), run

    def test_most_restrictive_window_wins(self):
        for name in ("primary", "secondary"):
            data = snapshot()
            self.assertEqual(
                self.summarize(data)["next_action"], "use-normal-delegation"
            )
            data[0]["pace"][name]["willLastToReset"] = False
            result = self.summarize(data)
            self.assertEqual(result["forecast"], "at-risk")
            self.assertEqual(result["next_action"], "conserve-optional-workers")
            del data[0]["usage"]["secondary" if name == "primary" else "primary"]
            self.assertEqual(self.summarize(data)["forecast"], "at-risk")

    def test_incomplete_windows_and_forecasts_are_unknown(self):
        for section, key in (
            ("usage", "primary"),
            ("usage", "secondary"),
            ("pace", "primary"),
            ("pace", "secondary"),
        ):
            data = snapshot()
            del data[0][section][key]
            self.assertEqual(self.summarize(data)["forecast"], "unknown")
        data = snapshot()
        data[0]["usage"]["extraRateWindows"] = [{"id": "private-account-id"}]
        self.assertEqual(self.summarize(data)["forecast"], "unknown")
        data[0]["pace"]["primary"]["willLastToReset"] = False
        self.assertEqual(self.summarize(data)["forecast"], "at-risk")

    def test_reported_tertiary_window_cannot_hide_risk(self):
        data = snapshot(provider="claude")
        self.assertEqual(
            quota.summarize(data, "claude", now=NOW)["forecast"], "on-track"
        )
        data[0]["usage"]["tertiary"] = dict(data[0]["usage"]["primary"])
        for pace, expected in (
            ({"willLastToReset": True}, "on-track"),
            ({"willLastToReset": False, "etaSeconds": 30}, "at-risk"),
            (None, "unknown"),
        ):
            with self.subTest(pace=pace):
                data[0]["pace"]["tertiary"] = pace
                result = quota.summarize(data, "claude", now=NOW)
                self.assertEqual(result["forecast"], expected)
                self.assertEqual(result["windows"][-1]["window"], "tertiary")

    def test_stale_future_and_missing_timestamp(self):
        for age in (301, -1):
            self.assertEqual(self.summarize(snapshot(age))["forecast"], "unknown")
        self.assertEqual(self.summarize(snapshot(300))["forecast"], "on-track")
        self.assertEqual(
            self.summarize(snapshot(301), max_age_seconds=400)["forecast"], "on-track"
        )
        data = snapshot()
        del data[0]["usage"]["updatedAt"]
        self.assertEqual(self.summarize(data)["forecast"], "unknown")

    def test_past_reset_never_implies_replenishment(self):
        for seconds in (0, -1):
            data = snapshot()
            data[0]["usage"]["primary"]["resetsAt"] = (
                NOW + timedelta(seconds=seconds)
            ).isoformat()
            self.assertEqual(self.summarize(data)["forecast"], "unknown")

    def test_eta_is_aged_and_boolean_cannot_hide_risk(self):
        for eta, expected in ((150, "at-risk"), (200, "on-track"), (50, "at-risk")):
            data = snapshot(age=100)
            data[0]["pace"]["primary"] = {"willLastToReset": True, "etaSeconds": eta}
            result = self.summarize(data)
            self.assertEqual(result["forecast"], expected)
            self.assertEqual(
                result["windows"][0]["eta_seconds_remaining"], max(0, eta - 100)
            )
        data[0]["pace"]["primary"] = {"etaSeconds": 250}
        self.assertEqual(self.summarize(data)["forecast"], "on-track")

    def test_override_neither_fetches_nor_reads_stdin(self):
        with mock.patch.object(quota.sys, "stdin") as stdin:
            stdin.read.side_effect = AssertionError("must not read stdin")
            with (
                mock.patch.object(quota.subprocess, "run") as run,
                mock.patch.object(
                    quota.sys, "stdout", new_callable=io.StringIO
                ) as output,
            ):
                self.assertEqual(
                    quota.main(
                        ["--provider", "claude", "--user-requested", "--from-stdin"]
                    ),
                    0,
                )
                result = json.loads(output.getvalue())
                self.assertEqual(result["next_action"], "follow-user-request")
                self.assertTrue(result["is_advisory"])
                stdin.read.assert_not_called()
                run.assert_not_called()
        _, run = self.cli("--user-requested")
        run.assert_not_called()

    def test_tool_failures_are_advisory_and_sanitized(self):
        for error in (
            FileNotFoundError("private-account-id"),
            subprocess.TimeoutExpired("codexbar", 10, output="secret"),
            subprocess.CalledProcessError(1, "codexbar", stderr="secret"),
        ):
            result, run = self.cli(error=error)
            self.assertEqual(result["next_action"], "use-normal-judgment")
            self.assertTrue(result["is_advisory"])
            self.assertNotIn("secret", json.dumps(result))
            run.assert_called_once()
            self.assertEqual(run.call_args.kwargs["timeout"], 10)
            self.assertEqual(run.call_args.kwargs["stderr"], subprocess.DEVNULL)
            self.assertEqual(
                run.call_args.args[0],
                [
                    "codexbar",
                    "usage",
                    "--provider",
                    "codex",
                    "--source",
                    "cli",
                    "--json",
                    "--no-credits",
                ],
            )

    def test_malformed_and_ambiguous_data(self):
        for raw in (
            "not json",
            "{}",
            "[]",
            "[null]",
            json.dumps(snapshot() * 2),
            json.dumps(snapshot(provider="claude")),
        ):
            result, run = self.cli("--from-stdin", stdin=raw)
            self.assertEqual(result["forecast"], "unknown")
            run.assert_not_called()
        result = self.summarize(snapshot())
        self.assertNotIn("private-account-id", json.dumps(result))
        for provider in quota.PROVIDERS:
            self.assertEqual(
                quota.summarize(snapshot(provider=provider), provider, now=NOW)[
                    "forecast"
                ],
                "on-track",
            )

    def test_invalid_forecasts_and_resets_do_not_claim_headroom(self):
        for eta in (None, -1, True, "1000", float("nan"), float("inf"), 10**400):
            data = snapshot()
            data[0]["pace"]["primary"] = {"etaSeconds": eta}
            data[0]["usage"]["primary"]["usedPercent"] = eta
            result = self.summarize(data)
            self.assertEqual(result["forecast"], "unknown")
            json.dumps(result, allow_nan=False)
        for reset in (None, "invalid", "2026-10-02T00:00:00"):
            data[0]["usage"]["primary"]["resetsAt"] = reset
            self.assertEqual(self.summarize(data)["forecast"], "unknown")

    def test_cli_rejects_invalid_max_age(self):
        for value in ("-1", "nan", "inf", "invalid"):
            with mock.patch.object(quota.sys, "stderr", io.StringIO()):
                with self.assertRaises(SystemExit) as raised:
                    quota.main(["--provider", "codex", "--max-age-seconds", value])
                self.assertEqual(raised.exception.code, 2)


if __name__ == "__main__":
    unittest.main()
