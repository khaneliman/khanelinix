import datetime as dt
import os
import unittest
from unittest.mock import patch

from codexbar_presentation import (
    billing_lines,
    pace_lines,
    quota_rows,
    reset_inventory,
    tooltip,
)

NOW = dt.datetime(2026, 9, 9, 20, 0, tzinfo=dt.UTC)


def window(used=0, minutes=300, resets="2026-09-09T21:56:00.000Z"):
    return {"usedPercent": used, "windowMinutes": minutes, "resetsAt": resets}


class PresentationTests(unittest.TestCase):
    def test_codex_remaining_and_claude_used_match_provider_pages(self):
        codex = quota_rows(
            {"provider": "codex", "usage": {"secondary": window(50, 10080)}}, NOW
        )[0]
        claude = quota_rows(
            {"provider": "claude", "usage": {"primary": window(0)}}, NOW
        )[0]
        self.assertEqual((codex.title, codex.value), ("Weekly", "50% left"))
        self.assertEqual(
            (claude.title, claude.value), ("Current session · 5-hour", "0% used")
        )
        self.assertEqual(claude.reset, "Resets in 1h 56m")

    def test_scoped_claude_model_keeps_provider_title_and_weekly_context(self):
        entry = {
            "provider": "claude",
            "usage": {
                "extraRateWindows": [
                    {"title": "Fable only", "window": window(60, 10080)}
                ]
            },
        }
        self.assertEqual(quota_rows(entry, NOW)[0].title, "Weekly · Fable only")

    def test_antigravity_removes_aliases_not_identical_distinct_scopes(self):
        short, weekly = window(), window(23.22396, 10080)
        entry = {
            "provider": "antigravity",
            "usage": {
                "primary": weekly,
                "secondary": short,
                "extraRateWindows": [
                    {"id": "antigravity-quota-summary-gemini-5h", "window": short},
                    {"id": "antigravity-quota-summary-gemini-weekly", "window": weekly},
                    {"id": "antigravity-quota-summary-3p-5h", "window": short},
                    {
                        "id": "antigravity-quota-summary-3p-weekly",
                        "window": window(0, 10080),
                    },
                ],
            },
        }
        rows = quota_rows(entry, NOW)
        self.assertEqual(
            [row.title for row in rows],
            [
                "Gemini · 5-hour",
                "Gemini · Weekly",
                "Claude/GPT · 5-hour",
                "Claude/GPT · Weekly",
            ],
        )
        self.assertEqual(rows[1].value, "23.2% used")

    def test_antigravity_partial_or_conflicting_extra_does_not_hide_base(self):
        entry = {
            "provider": "antigravity",
            "usage": {
                "primary": window(40, 10080),
                "secondary": window(),
                "extraRateWindows": [
                    {
                        "id": "antigravity-quota-summary-gemini-weekly",
                        "window": window(30, 10080),
                    }
                ],
            },
        }
        self.assertEqual(len(quota_rows(entry, NOW)), 3)

    def test_unknown_usage_never_renders_as_zero_or_a_bar(self):
        entry = {
            "provider": "antigravity",
            "usage": {
                "extraRateWindows": [
                    {"title": "Limited model", "usageKnown": False, "window": window()}
                ]
            },
        }
        row = quota_rows(entry, NOW)[0]
        self.assertEqual(row.value, "Unavailable")
        self.assertIsNone(row.used_percent)
        self.assertEqual(
            quota_rows({"usage": {"primary": {}}}, NOW)[0].value, "Unavailable"
        )

    def test_unknown_period_does_not_invent_session(self):
        entry = {"provider": "newprovider", "usage": {"primary": {"usedPercent": 5}}}
        self.assertEqual(quota_rows(entry, NOW)[0].title, "Quota 1")

    def test_copilot_uses_allowance_metadata(self):
        entry = {
            "provider": "copilot",
            "usage": {"primary": {"usedPercent": 0}, "details": [{"title": "Credits"}]},
        }
        self.assertEqual(quota_rows(entry, NOW)[0].title, "Monthly · Credits")

    def test_cached_description_cannot_override_timestamp(self):
        w = window()
        w["resetDescription"] = "Resets in 5 hours"
        row = quota_rows({"usage": {"primary": w}}, NOW)[0]
        self.assertEqual(row.reset, "Resets in 1h 56m")
        self.assertEqual(
            quota_rows({"usage": {"primary": w}}, NOW + dt.timedelta(hours=3))[0].reset,
            "Awaiting refresh",
        )

    def test_resolved_timezone_controls_exact_dates_not_countdowns(self):
        usage = {
            "primary": window(),
            "codexResetCredits": {
                "availableCount": 1,
                "credits": [
                    {"status": "available", "expires_at": "2026-10-05T04:18:34Z"}
                ],
            },
        }
        with patch.dict(os.environ, {"CODEXBAR_RESET_TIME_FORMAT": "local"}):
            row = quota_rows(
                {"provider": "codex", "usage": usage}, NOW, exact_mode="utc"
            )[0]
            self.assertEqual(row.reset, "Resets in 1h 56m")
            self.assertTrue(row.exact_reset.endswith("UTC"))
            self.assertTrue(
                reset_inventory(usage, NOW, exact_mode="utc")[1].endswith("UTC")
            )

    def test_invalid_or_missing_reset_is_unknown(self):
        for stamp in (None, "not a date", "2026-09-09T22:00:00"):
            row = quota_rows({"usage": {"primary": window(resets=stamp)}}, NOW)[0]
            self.assertEqual(row.reset, "Reset unknown")

    def test_reset_inventory_count_and_expiration_only(self):
        usage = {
            "codexResetCredits": {
                "availableCount": 1,
                "credits": [
                    {"status": "available", "expires_at": "2026-10-05T04:18:34.696769Z"}
                ],
            }
        }
        count, expiry = reset_inventory(usage, NOW)
        self.assertEqual(count, "1 reset available")
        self.assertTrue(expiry.startswith("Expires Oct "))
        self.assertNotIn("restores", expiry.lower())

    def test_multiple_resets_same_expiry_do_not_crash(self):
        credit = {"status": "available", "expires_at": "2026-10-05T04:18:34Z"}
        result = reset_inventory(
            {"codexResetCredits": {"availableCount": 2, "credits": [credit, credit]}},
            NOW,
        )
        self.assertEqual(result[0], "2 resets available")
        self.assertTrue(result[1].startswith("Next expires"))

    def test_expired_reset_inventory_is_not_available(self):
        usage = {
            "codexResetCredits": {
                "availableCount": 1,
                "credits": [
                    {"status": "available", "expires_at": "2026-09-01T00:00:00Z"}
                ],
            }
        }
        self.assertEqual(reset_inventory(usage, NOW), ("0 resets available", ""))

    def test_missing_reset_inventory_is_not_zero(self):
        self.assertIsNone(reset_inventory({}, NOW))
        self.assertEqual(
            reset_inventory({"codexResetCreditsUnavailable": True}, NOW),
            ("Unavailable", ""),
        )
        self.assertEqual(
            reset_inventory({"codexResetCredits": {"availableCount": 1}}, NOW),
            ("1 reset available", "Expiry unknown"),
        )

    def test_pace_estimate_ages_and_healthy_forecasts_are_secondary(self):
        entry = {
            "provider": "codex",
            "usage": {
                "secondary": window(50, 10080),
                "updatedAt": (NOW - dt.timedelta(hours=1)).isoformat(),
            },
            "pace": {"secondary": {"willLastToReset": False, "etaSeconds": 7200}},
        }
        self.assertEqual(pace_lines(entry, NOW), ["Weekly forecast: may run out in 1h"])
        entry["pace"]["secondary"]["willLastToReset"] = True
        self.assertEqual(pace_lines(entry, NOW, risks_only=True), [])
        self.assertEqual(pace_lines(entry, NOW), ["Weekly forecast: on track to reset"])

    def test_billing_deduplicates_and_suppresses_zero_noise(self):
        entry = {
            "credits": {"remaining": 5},
            "openaiDashboard": {"creditsRemaining": 5},
            "usage": {"providerCost": {"used": 0, "limit": 0}},
        }
        self.assertEqual(billing_lines(entry), ["Credits: $5.00 remaining"])
        entry["credits"]["remaining"] = entry["openaiDashboard"]["creditsRemaining"] = 0
        self.assertEqual(billing_lines(entry), [])

    def test_tooltip_escapes_external_content_and_marks_cached_provider(self):
        entry = {
            "provider": "claude",
            "account": "A&B",
            "stale": True,
            "usage": {"extraRateWindows": [{"title": "<model>", "window": window()}]},
        }
        rendered = tooltip([entry], NOW)
        self.assertIn("A&amp;B", rendered)
        self.assertIn("&lt;model&gt;", rendered)
        self.assertIn("cached", rendered)
        self.assertNotIn("primary", rendered)
        self.assertNotIn("secondary", rendered)


if __name__ == "__main__":
    unittest.main()
