#!/usr/bin/env python3
"""Give optional delegation advice, not permission or provider failure handling.

Callers must match the reported subscription/account to the actual worker route.
This helper does not authenticate, read credentials, or reserve capacity.
"""

from __future__ import annotations

import argparse
import json
import math
import subprocess
import sys
from datetime import datetime, timezone

PROVIDERS = ("codex", "claude", "antigravity")
MAX_INPUT = 1024 * 1024
ACTIONS = {
    "on-track": "use-normal-delegation",
    "at-risk": "conserve-optional-workers",
    "unknown": "use-normal-judgment",
}


def advice(provider, forecast="unknown", reason="quota-data-missing", windows=None):
    return {
        "provider": provider,
        "is_advisory": True,
        "forecast": forecast,
        "next_action": ACTIONS[forecast],
        "reason": reason,
        "windows": windows if windows is not None else [],
    }


def timestamp(value):
    if not isinstance(value, str):
        return None
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
        return parsed.astimezone(timezone.utc) if parsed.tzinfo else None
    except (ValueError, OverflowError):
        return None


def number(value):
    try:
        return type(value) in (int, float) and math.isfinite(value)
    except OverflowError:
        return False


def window_advice(name, usage, pace, age, now):
    result = {"window": name, "forecast": "unknown", "reason": "window-missing"}
    if not isinstance(usage, dict):
        return result
    used = usage.get("usedPercent")
    if number(used) and 0 <= used <= 100:
        result["used_percent"] = used
    reset = timestamp(usage.get("resetsAt"))
    if reset is None:
        result["reason"] = "reset-missing-or-invalid"
        return result
    result["resets_at"] = reset.isoformat()
    remaining = (reset - now).total_seconds()
    if remaining <= 0:
        result["reason"] = "reset-passed"
        return result
    result["seconds_to_reset"] = remaining
    if not isinstance(pace, dict):
        result["reason"] = "forecast-missing"
        return result
    lasts = pace.get("willLastToReset")
    eta = pace.get("etaSeconds")
    has_eta = number(eta) and eta >= 0
    if type(lasts) is bool:
        result["will_last_to_reset"] = lasts
    if has_eta:
        # ETA is relative to the snapshot, not the time this helper is called.
        result["eta_seconds_remaining"] = max(0, eta - age)
    if lasts is False or (has_eta and eta - age < remaining):
        result.update(forecast="at-risk", reason="projected-exhaustion-before-reset")
    elif lasts is True or has_eta:
        result.update(forecast="on-track", reason="projected-to-last-until-reset")
    else:
        result["reason"] = "forecast-missing"
    return result


def summarize(payload, provider, max_age_seconds=300, now=None):
    now = now if now is not None else datetime.now(timezone.utc)
    if not isinstance(payload, list) or any(
        not isinstance(row, dict) for row in payload
    ):
        return advice(provider, reason="quota-data-malformed")
    rows = [row for row in payload if row.get("provider") == provider]
    if len(rows) != 1:
        return advice(provider, reason="provider-or-account-ambiguous")
    row = rows[0]
    usage = row.get("usage")
    if row.get("error") or not isinstance(usage, dict):
        return advice(provider, reason="quota-data-unavailable")
    updated = timestamp(usage.get("updatedAt"))
    if updated is None:
        return advice(provider, reason="snapshot-timestamp-missing-or-invalid")
    age = (now - updated).total_seconds()
    if age < 0 or age > max_age_seconds:
        return advice(provider, reason="snapshot-future-or-stale")
    pace = row.get("pace")
    pace = pace if isinstance(pace, dict) else {}
    windows = [
        window_advice(name, usage.get(name), pace.get(name), age, now)
        for name in ("primary", "secondary", "tertiary")
        if name != "tertiary" or usage.get(name) is not None
    ]
    extra = usage.get("extraRateWindows")
    if extra is not None and extra != []:
        # No supported pace mapping exists for extra windows; do not echo IDs.
        windows.append(
            {
                "window": "extra-rate-windows",
                "forecast": "unknown",
                "reason": "extra-window-forecast-unsupported",
            }
        )
    forecasts = [window["forecast"] for window in windows]
    if "at-risk" in forecasts:
        result = advice(provider, "at-risk", "at-least-one-window-at-risk", windows)
    elif all(forecast == "on-track" for forecast in forecasts):
        result = advice(provider, "on-track", "all-reported-windows-on-track", windows)
    else:
        result = advice(provider, reason="window-evidence-incomplete", windows=windows)
    result["snapshot_age_seconds"] = age
    return result


def max_age(value):
    try:
        parsed = float(value)
    except ValueError:
        raise argparse.ArgumentTypeError(
            "must be a finite nonnegative number"
        ) from None
    if not math.isfinite(parsed) or parsed < 0:
        raise argparse.ArgumentTypeError("must be a finite nonnegative number")
    return parsed


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--provider", choices=PROVIDERS, required=True)
    parser.add_argument("--from-stdin", action="store_true")
    parser.add_argument("--user-requested", action="store_true")
    parser.add_argument("--max-age-seconds", type=max_age, default=300)
    args = parser.parse_args(argv)
    if args.user_requested:
        result = advice(args.provider, reason="explicit-user-request")
        result["next_action"] = "follow-user-request"
    else:
        try:
            if args.from_stdin:
                raw = sys.stdin.read(MAX_INPUT + 1)
            else:
                completed = subprocess.run(
                    [
                        "codexbar",
                        "usage",
                        "--provider",
                        args.provider,
                        "--source",
                        "cli",
                        "--json",
                        "--no-credits",
                    ],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.DEVNULL,
                    timeout=10,
                    check=True,
                    text=True,
                    encoding="utf-8",
                )
                raw = completed.stdout
            if len(raw) > MAX_INPUT:
                result = advice(args.provider, reason="quota-data-too-large")
            else:
                result = summarize(json.loads(raw), args.provider, args.max_age_seconds)
        except subprocess.TimeoutExpired:
            result = advice(args.provider, reason="quota-tool-timeout")
        except (OSError, subprocess.CalledProcessError):
            result = advice(args.provider, reason="quota-tool-unavailable-or-failed")
        except (ValueError, RecursionError):
            result = advice(args.provider, reason="quota-data-malformed")
    print(json.dumps(result, allow_nan=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
