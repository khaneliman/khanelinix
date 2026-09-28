"""Classify git and jj commands.

A lease push (--force-with-lease) counts as a push, because follow-ups
rewrite their own branches that way; plain --force, --mirror, and +refspecs
need "force push" in the user's words.
"""

from __future__ import annotations

from pathlib import Path

from .grants import DELETE, FORCE_PUSH, PUSH, Action
from .shell import Context, has_option, positionals, resolve_path

GIT_VALUE_GLOBALS = {
    "-C",
    "-c",
    "--git-dir",
    "--work-tree",
    "--namespace",
    "--exec-path",
}
JJ_VALUE_GLOBALS = {
    "-R",
    "--repository",
    "--at-op",
    "--at-operation",
    "--config",
    "--config-file",
    "--color",
}


def git_subcommand(
    args: list[str], context: Context
) -> tuple[str | None, list[str], Path]:
    cwd = context.cwd
    index = 0
    while index < len(args) and args[index].startswith("-"):
        option = args[index]
        if option in GIT_VALUE_GLOBALS and index + 1 < len(args):
            if option == "-C":
                cwd = resolve_path(args[index + 1], context) or cwd
            index += 2
        else:
            index += 1
    if index >= len(args):
        return None, [], cwd
    return args[index], args[index + 1 :], cwd


def classify_git(args: list[str], context: Context) -> list[Action]:
    sub, rest, _ = git_subcommand(args, context)
    if sub is None:
        return []
    if sub == "push":
        if has_option(rest, {"-n", "--dry-run"}):
            return []
        targets = positionals(
            rest, {"--repo", "-o", "--push-option", "--receive-pack", "--exec"}
        )
        grants = {PUSH}
        lease = has_option(rest, {"--force-with-lease", "--force-if-includes"})
        if (not lease and has_option(rest, {"-f", "--force"})) or has_option(
            rest, {"--mirror"}
        ):
            grants = {FORCE_PUSH}
        if any(target.startswith("+") for target in targets[1:]):
            grants = {FORCE_PUSH}
        if has_option(rest, {"-d", "--delete", "--prune"}) or any(
            target.startswith(":") for target in targets[1:]
        ):
            grants.add(DELETE)
        return [Action("git push", frozenset(grants), publishes=True)]
    return []


def classify_jj(args: list[str], context: Context) -> list[Action]:
    index = 0
    while index < len(args) and args[index].startswith("-"):
        index += 2 if args[index] in JJ_VALUE_GLOBALS else 1
    if index >= len(args):
        return []
    sub, rest = args[index], args[index + 1 :]
    if sub == "git":
        if rest[:1] == ["push"]:
            if has_option(rest, {"--dry-run"}):
                return []
            grants = {PUSH} | ({DELETE} if has_option(rest, {"--deleted"}) else set())
            return [Action("jj git push", frozenset(grants), publishes=True)]
        return []
    return []
