"""Grant keys, the actions that need them, and grants a launcher passes on."""

from __future__ import annotations

import os
import re

# A launcher, such as the headless nixpkgs update job, exports standing grants
# here. Hooks inherit the harness environment. An agent may only pass on
# grants its own session already holds, so delegation cannot widen authority.
GRANTS_ENV = "KHANELINIX_AUTHORITY_GRANTS"

REVIEW_DRAFT = "review-draft"
PUBLISH = "publish"
PUSH = "push"
FORCE_PUSH = "force-push"
MERGE = "merge"
APPROVE = "approve"
REQUEST_CHANGES = "request-changes"
RELEASE = "release"
DELETE = "delete"
ACTIVATE = "activate"
DISCLOSE = "disclose"

IMPLIED = {PUBLISH: {REVIEW_DRAFT}, FORCE_PUSH: {PUSH}}
NEEDS = {
    REVIEW_DRAFT: "create or change a pending review",
    PUBLISH: "publish to GitHub",
    PUSH: "push",
    FORCE_PUSH: "force-push",
    MERGE: "merge",
    APPROVE: "approve a review",
    REQUEST_CHANGES: "request changes",
    RELEASE: "manage a release",
    DELETE: "delete remote content",
    ACTIVATE: "activate a system or home configuration",
    DISCLOSE: "publish the flagged wording",
}

SETS_GRANTS = re.compile(rf"\b{GRANTS_ENV}\b\s*=")
GRANT_VALUE = re.compile(
    rf"\b{GRANTS_ENV}\s*=\s*(?:\"([^\"$`]*)\"|'([^'$`]*)'|([^\s;&|\"'$`]+))"
)


class Action:
    """One gated operation found in a command. Plain class: dataclasses import slowly."""

    def __init__(
        self,
        label: str,
        grants: frozenset[str] = frozenset(),
        *,
        publishes: bool = False,
        history: bool = False,
        unresolved_text: bool = False,
    ) -> None:
        self.label = label
        self.grants = grants
        self.publishes = publishes
        self.history = history
        self.unresolved_text = unresolved_text
        self.public_texts: list[str] = []


def environment_grants() -> set[str]:
    raw = os.environ.get(GRANTS_ENV, "")
    return {item for item in re.split(r"[\s,]+", raw) if item in NEEDS}


def expand_grants(grants: set[str]) -> set[str]:
    expanded = set(grants)
    for grant in grants:
        expanded |= IMPLIED.get(grant, set())
    return expanded


def delegated_grants(text: str) -> set[str] | None:
    """Return grants a command or file assigns, or None when unreadable."""
    requested: set[str] = set()
    for match in GRANT_VALUE.finditer(text):
        value = next((group for group in match.groups() if group is not None), "")
        keys = {item for item in re.split(r"[\s,]+", value) if item}
        if not keys <= set(NEEDS):
            return None
        requested |= keys
    if len(GRANT_VALUE.findall(text)) != len(SETS_GRANTS.findall(text)):
        return None
    return requested
