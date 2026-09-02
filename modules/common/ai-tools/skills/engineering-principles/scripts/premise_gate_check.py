#!/usr/bin/env python3
"""Check a review report or reviewer packet against the premise-review contract.

Exit 0 when the artifact passes, 1 when a rule fails, 2 on invalid input.
Output is one JSON object on stdout; diagnostics go to stderr.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

EXIT_PASS = 0
EXIT_FAIL = 1
EXIT_INVALID = 2

CONCERNS = (
    "problem",
    "solves",
    "issue fit",
    "existing capability",
    "native abstraction",
    "api boundary",
    "removable diff",
    "bundling",
    "handed premise",
    "reason not to merge",
)
LABELS = {
    "praise",
    "nitpick",
    "suggestion",
    "issue",
    "todo",
    "question",
    "thought",
    "chore",
    "note",
    "typo",
    "polish",
    "quibble",
}
DECORATIONS = {"blocking", "non-blocking", "if-minor"}
NEEDS_DECORATION = {"issue", "todo"}
APPROVING_VERDICTS = {"approved", "ready"}

HEADING = re.compile(r"^##\s+", re.MULTILINE)
GATE_HEADING = re.compile(r"^##\s+premise gate\s*$", re.IGNORECASE | re.MULTILINE)
FINDINGS_HEADING = re.compile(r"^##\s+findings\b", re.IGNORECASE | re.MULTILINE)
COMMENT = re.compile(
    r"^(?P<label>[a-z]+)(?:\s*\((?P<decoration>[a-z-]+)\))?:\s*(?P<subject>\S.*)$",
    re.IGNORECASE,
)
FINAL_VERDICT = re.compile(
    r"^\**verdict\**:\s*`?(approved|changes_requested|blocked|ready|not-ready)`?",
    re.IGNORECASE | re.MULTILINE,
)
PACKET_FIELD = re.compile(r"^-\s*([A-Za-z][A-Za-z ]*?):\s*(.*\S)\s*$", re.MULTILINE)

REQUIRED_PACKET_FIELDS = (
    "independence",
    "problem",
    "repository context",
    "target",
    "write policy",
    "required evidence",
)
SOLUTION_FIELDS = ("author claims", "claims", "solution", "chosen solution", "design")


def gate_comments(section: str) -> list[dict[str, str]]:
    """Split the gate section into conventional comments with their discussion."""
    comments: list[dict[str, str]] = []
    for line in section.splitlines()[1:]:
        match = COMMENT.match(line.strip())
        if match is not None and match.group("label").lower() in LABELS:
            comments.append(
                {
                    "label": match.group("label").lower(),
                    "decoration": (match.group("decoration") or "").lower(),
                    "subject": match.group("subject").strip(),
                    "discussion": "",
                }
            )
        elif comments and line.strip():
            comments[-1]["discussion"] += " " + line.strip()
    return comments


def concern_of(subject: str) -> tuple[str, str]:
    """Return (concern, evidence) for a gate subject, or ('', subject)."""
    lowered = subject.lower()
    for concern in sorted(CONCERNS, key=len, reverse=True):
        if lowered.startswith(concern + ":"):
            return concern, subject[len(concern) + 1 :].strip()
    return "", subject


def check_review(text: str) -> tuple[list[dict[str, str]], dict[str, object]]:
    failures: list[dict[str, str]] = []
    details: dict[str, object] = {}

    heading = GATE_HEADING.search(text)
    if heading is None:
        failures.append({"rule": "missing_gate", "detail": "no '## Premise gate' section"})
        return failures, details

    next_heading = HEADING.search(text, heading.end())
    section = text[heading.start() : next_heading.start() if next_heading else len(text)]

    covered: set[str] = set()
    blocking: set[str] = set()
    for comment in gate_comments(section):
        concern, evidence = concern_of(comment["subject"])
        if not concern:
            failures.append(
                {"rule": "unknown_concern", "detail": comment["subject"][:60]}
            )
            continue
        covered.add(concern)
        if comment["decoration"] and comment["decoration"] not in DECORATIONS:
            failures.append(
                {"rule": "invalid_decoration", "detail": f"{concern}: ({comment['decoration']})"}
            )
        if comment["label"] in NEEDS_DECORATION and not comment["decoration"]:
            failures.append(
                {
                    "rule": "undecorated_issue",
                    "detail": f"{concern}: '{comment['label']}' needs (blocking) or (non-blocking)",
                }
            )
        if not (evidence + comment["discussion"]).strip():
            failures.append(
                {"rule": "unsupported_comment", "detail": f"{concern} carries no evidence"}
            )
        if comment["decoration"] == "blocking":
            blocking.add(concern)

    missing = [concern for concern in CONCERNS if concern not in covered]
    if missing:
        failures.append(
            {"rule": "missing_concerns", "detail": "unaddressed: " + ", ".join(missing)}
        )

    final = FINAL_VERDICT.search(text)
    if final is None:
        failures.append({"rule": "missing_final_verdict", "detail": "no 'Verdict:' line"})
    else:
        details["final_verdict"] = final.group(1).lower()
        if final.start() < heading.start():
            failures.append(
                {"rule": "gate_after_verdict", "detail": "verdict precedes the premise gate"}
            )

    findings = FINDINGS_HEADING.search(text)
    if findings is not None and findings.start() < heading.start():
        failures.append(
            {"rule": "gate_after_findings", "detail": "findings precede the premise gate"}
        )

    details["covered"] = sorted(covered)
    details["blocking"] = sorted(blocking)
    details["clean"] = not blocking and not missing
    if blocking and details.get("final_verdict") in APPROVING_VERDICTS:
        failures.append(
            {
                "rule": "verdict_contradicts_gate",
                "detail": f"final verdict {details['final_verdict']!r} beside blocking premise comments: "
                + ", ".join(sorted(blocking)),
            }
        )
    return failures, details


def check_packet(text: str) -> tuple[list[dict[str, str]], dict[str, object]]:
    failures: list[dict[str, str]] = []
    fields: dict[str, str] = {}
    for match in PACKET_FIELD.finditer(text):
        fields.setdefault(match.group(1).strip().lower(), match.group(2).strip())

    for name in REQUIRED_PACKET_FIELDS:
        if not fields.get(name):
            failures.append({"rule": "missing_field", "detail": f"packet lacks '{name}'"})

    independence = fields.get("independence", "").lower()
    if independence and independence not in {"blind", "informed"}:
        failures.append(
            {
                "rule": "invalid_status",
                "detail": f"independence {independence!r} is not blind or informed",
            }
        )
    if "write policy" in fields and "read-only" not in fields["write policy"].lower():
        failures.append({"rule": "write_policy", "detail": "review packets must be read-only"})
    if (
        "required evidence" in fields
        and "premise gate" not in fields["required evidence"].lower()
    ):
        failures.append(
            {"rule": "missing_field", "detail": "required evidence does not name the premise gate"}
        )
    if independence == "blind":
        leaked = [name for name in SOLUTION_FIELDS if name in fields]
        if leaked:
            failures.append(
                {
                    "rule": "blind_packet_leaks_solution",
                    "detail": "blind packet carries: " + ", ".join(leaked),
                }
            )
    return failures, {"independence": independence, "fields": sorted(fields)}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("review", "packet"))
    parser.add_argument("path", type=Path)
    args = parser.parse_args(argv)
    try:
        text = args.path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as error:
        print(f"premise-gate-check: {error}", file=sys.stderr)
        return EXIT_INVALID

    checker = check_review if args.mode == "review" else check_packet
    failures, details = checker(text)
    result = {
        "mode": args.mode,
        "path": str(args.path),
        "passed": not failures,
        "failures": failures,
        "details": details,
    }
    print(json.dumps(result, sort_keys=True))
    return EXIT_PASS if not failures else EXIT_FAIL


if __name__ == "__main__":
    raise SystemExit(main())
