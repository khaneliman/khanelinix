"""Classify git and jj commands.

A lease push (--force-with-lease) counts as a push, because follow-ups
rewrite their own branches that way; plain --force, --mirror, and +refspecs
need "force push" in the user's words.
"""

from __future__ import annotations

import re
from pathlib import Path

from .grants import DELETE, FORCE_PUSH, PUSH, Action
from .shell import (
    Context,
    has_option,
    option_values,
    positionals,
    read_limited,
    resolve_path,
)

GIT_VALUE_GLOBALS = {
    "-C",
    "-c",
    "--git-dir",
    "--work-tree",
    "--namespace",
    "--exec-path",
}
GIT_HISTORY = {
    "add",
    "am",
    "checkout",
    "cherry-pick",
    "clean",
    "commit",
    "filter-branch",
    "filter-repo",
    "merge",
    "mv",
    "pull",
    "rebase",
    "replace",
    "reset",
    "restore",
    "revert",
    "rm",
    "switch",
    "update-ref",
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
JJ_HISTORY = {
    "abandon",
    "absorb",
    "backout",
    "ci",
    "commit",
    "desc",
    "describe",
    "diffedit",
    "duplicate",
    "edit",
    "fix",
    "metaedit",
    "new",
    "next",
    "parallelize",
    "prev",
    "rebase",
    "redo",
    "resolve",
    "restore",
    "revert",
    "simplify-parents",
    "split",
    "squash",
    "undo",
    "unsquash",
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
    sub, rest, cwd = git_subcommand(args, context)
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
        return [Action("git push", frozenset(grants), publishes=True, history=True)]
    history = sub in GIT_HISTORY
    if sub == "stash":
        history = not rest or rest[0] not in {"list", "show"}
    elif sub == "branch":
        history = has_option(
            rest, {"-d", "-D", "--delete", "-m", "-M", "--move", "-f", "--force"}
        )
    elif sub == "tag":
        history = bool(positionals(rest, {"-m", "-F", "-u"})) and not has_option(
            rest, {"-l", "--list", "-v", "--verify"}
        )
    elif sub == "worktree":
        history = bool(rest) and rest[0] in {"remove", "prune", "move"}
    elif sub in {"notes", "reflog"}:
        history = bool(rest) and rest[0] in {
            "add",
            "append",
            "copy",
            "edit",
            "remove",
            "prune",
            "expire",
            "delete",
        }
    if not history:
        return []
    action = Action(f"git {sub}", history=True)
    if sub == "commit":
        action.commit_texts.extend(option_values(rest, {"-m", "--message"}))
        action.commit_texts.extend(
            rest[index + 1]
            for index, item in enumerate(rest[:-1])
            if re.fullmatch(r"-[A-Za-z]+m", item)
        )
        action.commit_texts.extend(option_values(rest, {"--trailer"}))
        for source in option_values(rest, {"-F", "--file"}):
            if source == "-" and not context.heredocs:
                # Piped message: its text is in the command, with printf escapes.
                action.commit_texts.append(context.raw.replace("\\n", "\n"))
            elif source == "-":
                action.commit_texts.extend(body for _, body in context.heredocs)
            elif (
                text := read_limited(resolve_path(source, Context(cwd, "", [])))
            ) is not None:
                action.commit_texts.append(text)
        if any("$(" in text for text in action.commit_texts):
            action.commit_texts.extend(body for _, body in context.heredocs)
    return [action]


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
            return [
                Action("jj git push", frozenset(grants), publishes=True, history=True)
            ]
        if rest[:1] in (["import"], ["export"]):
            return [Action(f"jj git {rest[0]}", history=True)]
        return []
    history = sub in JJ_HISTORY
    if sub in {"bookmark", "b"}:
        history = bool(rest) and rest[0] not in {"list", "l"}
    elif sub in {"op", "operation"}:
        history = bool(rest) and rest[0] in {"restore", "revert", "abandon", "undo"}
    elif sub == "workspace":
        history = bool(rest) and rest[0] in {"add", "forget", "rename", "update-stale"}
    if not history:
        return []
    action = Action(f"jj {sub}", history=True)
    if sub in {"commit", "ci", "describe", "desc", "new"}:
        action.commit_texts.extend(option_values(rest, {"-m", "--message"}))
    return [action]
