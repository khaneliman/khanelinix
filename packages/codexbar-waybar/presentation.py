"""Quota names and compact presentation shared by the tooltip and GTK popup."""

import datetime as dt
import html
import json
import math
import os
import sys
from dataclasses import dataclass

UTC = dt.UTC
SLOTS = ("primary", "secondary", "tertiary")
PROVIDERS = {
    "codex": "Codex",
    "claude": "Claude",
    "antigravity": "Antigravity",
    "copilot": "Copilot",
    "gemini": "Gemini",
    "openai": "OpenAI",
    "openrouter": "OpenRouter",
    "commandcode": "Command Code",
    "zai": "z.ai",
}


def provider_name(provider):
    return PROVIDERS.get(provider, str(provider or "Unknown").replace("-", " ").title())


def parse_iso(value):
    if not isinstance(value, str):
        return None
    try:
        value = dt.datetime.fromisoformat(value)
        return value.astimezone(UTC) if value.tzinfo else None
    except ValueError:
        return None


def duration(seconds):
    minutes = max(1, math.ceil(seconds / 60))
    hours, minutes = divmod(minutes, 60)
    days, hours = divmod(hours, 24)
    if days:
        return f"{days}d" + (f" {hours}h" if hours else "")
    if hours:
        return f"{hours}h" + (f" {minutes}m" if minutes else "")
    return f"{minutes}m"


def exact_date(value, mode=None):
    timestamp = parse_iso(value)
    if timestamp is None:
        return "Unknown"
    timestamp = (
        timestamp
        if (mode or os.environ.get("CODEXBAR_RESET_TIME_FORMAT")) == "utc"
        else timestamp.astimezone()
    )
    year = " %Y" if timestamp.year != dt.datetime.now(UTC).year else ""
    return timestamp.strftime(f"%b %-d{year}, %-I:%M %p %Z")


def reset_text(window, now):
    timestamp = parse_iso(window.get("resetsAt"))
    if timestamp is None:
        return "Reset unknown"
    seconds = (timestamp - now).total_seconds()
    return "Awaiting refresh" if seconds <= 0 else f"Resets in {duration(seconds)}"


def number(value):
    return type(value) in (int, float) and math.isfinite(value)


def period(window, fallback=""):
    minutes = window.get("windowMinutes")
    known = {300: "5-hour", 1440: "Daily", 10080: "Weekly", 43200: "Monthly"}
    if number(minutes) and minutes > 0:
        return known.get(
            minutes,
            f"{minutes / 60:g}-hour" if minutes % 60 == 0 else f"{minutes:g}-minute",
        )
    return fallback


def base_label(entry, key, window):
    provider = entry.get("provider")
    if provider == "codex":
        return period(
            window,
            {"primary": "5-hour", "secondary": "Weekly"}.get(key, "Additional quota"),
        )
    if provider == "claude":
        if key == "primary":
            return f"Current session · {period(window, '5-hour')}"
        if key == "secondary":
            return f"{period(window, 'Weekly')} · All models"
        return f"{period(window, 'Weekly')} · Model-specific"
    if provider == "antigravity" and key in ("primary", "secondary"):
        scope = "Gemini" if key == "primary" else "Claude/GPT"
        return f"{scope} · {period(window, 'Quota')}"
    if provider == "copilot" and key == "primary":
        details = (entry.get("usage") or {}).get("details") or []
        title = next(
            (
                item.get("title")
                for item in details
                if isinstance(item, dict) and item.get("title")
            ),
            "Allowance",
        )
        return f"Monthly · {title}"
    return period(window, f"Quota {SLOTS.index(key) + 1}")


@dataclass
class Quota:
    title: str
    window: dict
    value: str
    used_percent: float | None
    reset: str
    exact_reset: str


def quota_rows(entry, now=None, exact_mode=None):
    now = now or dt.datetime.now(UTC)
    usage = entry.get("usage") or {}
    extras = [
        item
        for item in usage.get("extraRateWindows") or []
        if isinstance(item, dict) and isinstance(item.get("window"), dict)
    ]
    windows = []
    for key in SLOTS:
        window = usage.get(key)
        if not isinstance(window, dict):
            continue
        if entry.get("provider") == "antigravity" and key in ("primary", "secondary"):
            scope = "gemini" if key == "primary" else "3p"
            prefix = f"antigravity-quota-summary-{scope}-"
            # Only discard an alias when its own named scope reports the same window.
            if any(
                str(item.get("id", "")).startswith(prefix)
                and item.get("usageKnown") is not False
                and item["window"] == window
                for item in extras
            ):
                continue
        windows.append((base_label(entry, key, window), window, True))
    for item in extras:
        window = item["window"]
        title = str(item.get("title") or item.get("id") or "Additional quota")
        if entry.get("provider") == "antigravity":
            identifier = str(item.get("id") or "")
            for scope_id, scope in (("gemini", "Gemini"), ("3p", "Claude/GPT")):
                if identifier.startswith(f"antigravity-quota-summary-{scope_id}-"):
                    title = f"{scope} · {period(window, 'Quota')}"
        elif (
            entry.get("provider") == "claude"
            and period(window) == "Weekly"
            and "weekly" not in title.lower()
        ):
            title = f"Weekly · {title}"
        windows.append((title, window, item.get("usageKnown") is not False))
    rows = []
    for title, window, known in windows:
        used = window.get("usedPercent")
        used = used if known and number(used) else None
        left = entry.get("provider") == "codex"
        value = (
            "Unavailable"
            if used is None
            else f"{max(0, 100 - used) if left else used:.1f}".removesuffix(".0")
            + ("% left" if left else "% used")
        )
        rows.append(
            Quota(
                title,
                window,
                value,
                used,
                reset_text(window, now),
                exact_date(window.get("resetsAt"), exact_mode),
            )
        )
    return rows


def reset_inventory(usage, now=None, exact_mode=None):
    now = now or dt.datetime.now(UTC)
    snapshot = usage.get("codexResetCredits")
    if not isinstance(snapshot, dict):
        return (
            ("Unavailable", "") if usage.get("codexResetCreditsUnavailable") else None
        )
    count = snapshot.get("availableCount")
    if type(count) is not int or count < 0:
        return "Unavailable", ""
    credits = [
        item
        for item in snapshot.get("credits") or []
        if isinstance(item, dict) and item.get("status") == "available"
    ]
    expired = sum(
        1
        for item in credits
        if (stamp := parse_iso(item.get("expires_at") or item.get("expiresAt")))
        and stamp <= now
    )
    count = max(0, count - expired)
    summary = f"{count} reset{'s' if count != 1 else ''} available"
    if count == 0:
        return summary, ""
    expiries = [
        (parse_iso(item.get("expires_at") or item.get("expiresAt")), item)
        for item in credits
    ]
    future = sorted((stamp for stamp, item in expiries if stamp and stamp > now))
    if future:
        stamp = future[0]
        prefix = "Expires" if count == 1 else "Next expires"
        return summary, f"{prefix} {exact_date(stamp.isoformat(), exact_mode)}"
    return summary, "Expiry unknown"


def pace_lines(entry, now=None, risks_only=False):
    now = now or dt.datetime.now(UTC)
    usage = entry.get("usage") or {}
    updated = parse_iso(usage.get("updatedAt"))
    age = max(0, (now - updated).total_seconds()) if updated else 0
    result = []
    for key, pace in (entry.get("pace") or {}).items():
        window = usage.get(key)
        if (
            key not in SLOTS
            or not isinstance(pace, dict)
            or not isinstance(window, dict)
        ):
            continue
        lasts = pace.get("willLastToReset")
        label = base_label(entry, key, window)
        if entry.get("provider") == "claude":
            label = "Session" if key == "primary" else "Weekly"
        if lasts is True:
            if risks_only:
                continue
            text = "on track to reset"
        elif lasts is False:
            eta = pace.get("etaSeconds")
            text = (
                f"may run out in {duration(eta - age)}"
                if number(eta) and eta > age
                else "may run out before reset"
            )
        else:
            continue
        result.append(f"{label} forecast: {text}")
    return result


def billing_lines(entry):
    usage = entry.get("usage") or {}
    result = []

    def money(value, currency="USD"):
        return f"${value:,.2f}" if currency == "USD" else f"{value:,.2f} {currency}"

    for data in (entry.get("credits") or {}, entry.get("openaiDashboard") or {}):
        remaining = data.get("remaining", data.get("creditsRemaining"))
        if number(remaining) and remaining != 0:
            result.append(f"Credits: {money(remaining)} remaining")
        limit = data.get("codexCreditLimit") or {}
        if (
            number(limit.get("limit"))
            and limit["limit"] > 0
            and number(limit.get("used"))
        ):
            result.append(
                f"{limit.get('title') or 'Monthly credit limit'}: {money(limit['used'])} / {money(limit['limit'])}"
            )
    cost = usage.get("providerCost") or {}
    used, limit = cost.get("used"), cost.get("limit")
    if number(used) and (used != 0 or (number(limit) and limit > 0)):
        currency = cost.get("currencyCode") or "USD"
        line = f"{cost.get('period') or 'Extra usage'}: {money(used, currency)}"
        result.append(
            line
            + (
                f" / {money(limit, currency)}"
                if number(limit) and limit > 0
                else " used"
            )
        )
    for field, key, title in (
        ("openRouterUsage", "balance", "Balance"),
        ("sakanaPayAsYouGo", "creditBalance", "Pay-as-you-go"),
    ):
        value = (usage.get(field) or {}).get(key)
        if number(value) and value != 0:
            result.append(f"{title}: {money(value)}")
    return list(dict.fromkeys(result))


def tooltip(entries, now=None, exact_mode=None):
    now = now or dt.datetime.now(UTC)

    def muted(text):
        return f'<span size="small" foreground="#9aa5ce">{html.escape(text)}</span>'

    sections = []
    for entry in entries:
        name = provider_name(entry.get("provider"))
        if entry.get("account"):
            name += f" ({entry['account']})"
        if entry.get("stale"):
            name += " · cached"
        heading = (
            f'<span size="large" foreground="#7aa2f7"><b>{html.escape(name)}</b></span>'
        )
        lines = []
        if entry.get("error"):
            message = str(entry["error"].get("message") or "Unavailable")
            lines.append(f'<span foreground="#f7768e">{html.escape(message)}</span>')
        else:
            rows = quota_rows(entry, now, exact_mode)
            for row in rows:
                color = "#c0caf5"
                if row.used_percent is not None:
                    if row.used_percent >= 90:
                        color = "#f7768e"
                    elif row.used_percent >= 70:
                        color = "#e0af68"
                title = html.escape(f"{row.title:<26}")
                value = html.escape(f"{row.value:>11}")
                lines.append(
                    f"{title}  "
                    f'<span foreground="{color}"><b>{value}</b></span>'
                    f"  {muted(row.reset)}"
                )
            if not rows:
                lines.append(muted("Quota unavailable"))
            inventory = reset_inventory(entry.get("usage") or {}, now, exact_mode)
            if inventory:
                summary, expiry = inventory
                line = f"<b>{html.escape(summary)}</b>"
                if expiry:
                    line += f"  {muted(expiry)}"
                lines.append(line)
            for forecast in pace_lines(entry, now, risks_only=True):
                lines.append(
                    f'<span size="small" foreground="#e0af68">{html.escape(forecast)}</span>'
                )
            lines.extend(muted(f"Billing · {line}") for line in billing_lines(entry))
            status = entry.get("status") or {}
            if status.get("indicator") not in (None, "none", "operational"):
                lines.append(
                    muted(f"Status: {status.get('description') or status['indicator']}")
                )
        sections.append(heading + "\n" + "\n".join(f"  {line}" for line in lines))
    return "\n\n".join(sections)


if __name__ == "__main__":
    print(tooltip(json.load(sys.stdin)), end="")
