"""Find the gated actions a shell command would run."""

from __future__ import annotations

import re
from pathlib import Path

from .github import classify_gh, classify_gh_review, classify_helper
from .grants import ACTIVATE, APPROVE, GRANTS_ENV, MERGE, PUBLISH, PUSH, RELEASE, Action
from .shell import (
    ASSIGNMENT,
    Context,
    expand,
    has_option,
    read_limited,
    resolve_path,
    script_operand,
    simple_commands,
    split_heredocs,
    substitutions,
    tokenize,
    unwrap,
)
from .vcs import classify_git, classify_jj

TRIGGER = re.compile(
    r"\b(?:gh|git|jj|nixpkgs-review|review_draft|review_threads|nixos-rebuild|"
    r"nixos-rebuild-ng|darwin-rebuild|home-manager|nh|activate|"
    r"switch-to-configuration)\b|\.sh\b|\b(?:bash|sh|zsh|dash|ksh)\s+[^-\s]|"
    + GRANTS_ENV
)


def classify_activation(head: str, argv: list[str]) -> list[Action]:
    args = argv[1:]
    if has_option(args, {"--dry-run", "--dry", "-n"}):
        return []
    if head in {"nixos-rebuild", "nixos-rebuild-ng"} and {
        "switch",
        "boot",
        "test",
    } & set(args):
        return [
            Action(
                f"{head} {next(a for a in args if a in {'switch', 'boot', 'test'})}",
                frozenset({ACTIVATE}),
            )
        ]
    if head == "darwin-rebuild" and {"switch", "activate"} & set(args):
        return [Action("darwin-rebuild switch", frozenset({ACTIVATE}))]
    if head == "home-manager" and "switch" in args:
        return [Action("home-manager switch", frozenset({ACTIVATE}))]
    if (
        head == "nh"
        and len(args) > 1
        and args[0] in {"os", "home", "darwin"}
        and args[1] in {"switch", "boot", "test"}
    ):
        return [Action(f"nh {args[0]} {args[1]}", frozenset({ACTIVATE}))]
    if head == "switch-to-configuration" and {"switch", "boot", "test"} & set(args):
        return [Action("switch-to-configuration", frozenset({ACTIVATE}))]
    if (
        head == "activate"
        and "/" in argv[0]
        and ("home-manager" in argv[0] or "result" in argv[0])
    ):
        return [Action("home-manager activate", frozenset({ACTIVATE}))]
    return []


def classify(argv: list[str], context: Context) -> list[Action]:
    head = Path(argv[0]).name
    args = argv[1:]
    if "--help" in args or "-h" in args or args[:1] == ["help"]:
        return []
    if head == "gh":
        while args and args[0].split("=", 1)[0] in {"-R", "--repo", "--hostname"}:
            args = args[1:] if "=" in args[0] else args[2:]
        if args[:2] == ["pr", "review"]:
            return classify_gh_review(args, context)
        return classify_gh(args, context)
    if head == "git":
        return classify_git(args, context)
    if head == "jj":
        return classify_jj(args, context)
    if head == "nixpkgs-review":
        if "post-result" in args or has_option(args, {"--post-result"}):
            return [
                Action(
                    "nixpkgs-review post-result", frozenset({PUBLISH}), publishes=True
                )
            ]
        if args[:1] == ["approve"]:
            return [
                Action("nixpkgs-review approve", frozenset({APPROVE}), publishes=True)
            ]
        if args[:1] == ["merge"]:
            return [Action("nixpkgs-review merge", frozenset({MERGE}), publishes=True)]
        return []
    if head in {"review_draft.py", "review_threads.py"}:
        return classify_helper(head, args, context)
    if re.fullmatch(r"python[0-9.]*", head):
        scripts = [item for item in args if not item.startswith("-")]
        if scripts and Path(scripts[0]).name in {
            "review_draft.py",
            "review_threads.py",
        }:
            return classify_helper(
                Path(scripts[0]).name, args[args.index(scripts[0]) + 1 :], context
            )
        return []
    return classify_activation(head, argv)


def analyze(command: str, context: Context, depth: int = 0) -> list[Action]:
    if depth > 4:
        return []
    text, heredocs = split_heredocs(command)
    tokens = tokenize(text)
    if tokens is None:
        text, heredocs = command, []
        tokens = tokenize(command)
    if tokens is None:
        return fallback_actions(command)
    context = Context(
        context.cwd, context.raw, context.heredocs + heredocs, context.variables
    )
    actions: list[Action] = []
    for nested in substitutions(text):
        actions.extend(analyze(nested, context, depth + 1))
    for prefix, body in heredocs:
        if re.search(
            r"(?:^|[;&|(]\s*)(?:\S*/)?(?:bash|sh|zsh|dash)\b[^<]*$", prefix.strip()
        ):
            actions.extend(analyze(body, context, depth + 1))
    for argv in simple_commands(tokens):
        if all(ASSIGNMENT.match(item) for item in argv):
            for item in argv:
                name, _, value = item.partition("=")
                context.variables[name] = expand(value, context) or value
            continue
        unwrapped, nested_scripts = unwrap(argv)
        for script in nested_scripts:
            actions.extend(analyze(script, context, depth + 1))
        if not unwrapped:
            continue
        if Path(unwrapped[0]).name in {"cd", "pushd"} and len(unwrapped) > 1:
            context.cwd = resolve_path(unwrapped[1], context) or context.cwd
            continue
        if script := script_operand(unwrapped):
            body = read_limited(resolve_path(script, context))
            if body is not None:
                actions.extend(analyze(body, context, depth + 1))
            continue
        actions.extend(classify(unwrapped, context))
    return actions


COMMAND_START = r"(?:^|[;&|({]|\$\()\s*(?:sudo\s+|env\s+(?:\S+=\S*\s+)*)?(?:\S*/)?"
FALLBACK = tuple(
    (re.compile(COMMAND_START + pattern, re.MULTILINE | re.DOTALL), frozenset(grants))
    for pattern, grants in (
        (
            r"gh\s+(?:pr|issue)\s+(?:create|edit|comment|close|reopen|ready|review)\b",
            {PUBLISH},
        ),
        (r"gh\s+pr\s+merge\b", {MERGE}),
        (r"git\s+(?:-[Cc]\s+\S+\s+)*push\b", {PUSH}),
        (r"jj\s+git\s+push\b", {PUSH}),
        (r"gh\s+api\b.*\bmutation\b", {PUBLISH}),
        (
            (
                r"gh\s+api\b(?![^\n]*(?:-X|--method)[ =]?(?:GET|HEAD)\b)[^\n]*"
                r"(?:-X|--method|-f|-F|--field|--raw-field|--input)\b"
            ),
            {PUBLISH},
        ),
        (r"gh\s+release\s+(?:create|edit|upload|delete)\b", {RELEASE}),
        (r"nixpkgs-review\b[^\n]*\bpost-result\b", {PUBLISH}),
        (
            (
                r"(?:nixos-rebuild|darwin-rebuild|home-manager|nh\s+(?:os|home|darwin))\b"
                r"[^\n]*\b(?:switch|boot|test)\b"
            ),
            {ACTIVATE},
        ),
    )
)


def fallback_actions(command: str) -> list[Action]:
    """Classify unparsable shell conservatively by pattern."""
    return [
        Action(
            "unparsed command",
            grants,
            publishes=True,
            unresolved_text=True,
        )
        for pattern, grants in FALLBACK
        if pattern.search(command)
    ]
