"""Split shell commands into simple commands without running them."""

from __future__ import annotations

import os
import re
import shlex
from pathlib import Path

MAX_BODY_BYTES = 512 * 1024

HEREDOC_START = re.compile(
    r"(?<!<)<<(-?)\s*(?:'([A-Za-z_][A-Za-z0-9_]*)'|\"([A-Za-z_][A-Za-z0-9_]*)\"|"
    r"\\?([A-Za-z_][A-Za-z0-9_]*))"
)
ASSIGNMENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")
VARIABLE = re.compile(r"\$\{([A-Za-z_][A-Za-z0-9_]*)\}|\$([A-Za-z_][A-Za-z0-9_]*)")
SHELLS = {"bash", "sh", "zsh", "dash", "ksh", "fish"}
RESERVED_WORDS = frozenset(
    {
        "if",
        "then",
        "else",
        "elif",
        "fi",
        "do",
        "done",
        "while",
        "until",
        "!",
        "{",
        "}",
        "esac",
    }
)
SIMPLE_WRAPPERS = {
    "builtin",
    "caffeinate",
    "chronic",
    "command",
    "doas",
    "exec",
    "ionice",
    "nice",
    "nohup",
    "setsid",
    "stdbuf",
    "time",
    "unbuffer",
}
WRAPPER_VALUE_OPTIONS = {
    "env": {"-u", "--unset", "-C", "--chdir", "-S", "--split-string"},
    "sudo": {"-u", "--user", "-g", "--group", "-h", "--host", "-p", "--prompt", "-C"},
    "timeout": {"-s", "--signal", "-k", "--kill-after"},
    "xargs": {"-a", "-d", "-E", "-I", "-L", "-n", "-P", "-s", "--arg-file"},
    "nice": {"-n", "--adjustment"},
    "ionice": {"-c", "-n", "-t"},
    "watch": {"-n", "--interval", "-d"},
    "flock": {"-w", "--timeout", "-E"},
}


class Context:
    def __init__(
        self,
        cwd: Path,
        raw: str,
        heredocs: list[tuple[str, str]],
        variables: dict[str, str] | None = None,
    ) -> None:
        self.cwd = cwd
        self.raw = raw
        self.heredocs = heredocs
        self.variables = {} if variables is None else variables


def expand(value: str, context: Context) -> str | None:
    if value.startswith("~"):
        value = str(Path.home()) + value[1:]

    def replace(match: re.Match[str]) -> str:
        name = match.group(1) or match.group(2)
        return context.variables.get(name, os.environ.get(name, "\0"))

    expanded = VARIABLE.sub(replace, value)
    return None if "\0" in expanded or "$" in expanded else expanded


def resolve_path(value: str, context: Context) -> Path | None:
    expanded = expand(value, context)
    if expanded is None:
        return None
    path = Path(expanded)
    return path if path.is_absolute() else context.cwd / path


def read_limited(path: Path | None) -> str | None:
    if path is None:
        return None
    try:
        with path.open("rb") as handle:
            data = handle.read(MAX_BODY_BYTES)
    except OSError:
        return None
    return data.decode("utf-8", errors="replace")


def split_heredocs(command: str) -> tuple[str, list[tuple[str, str]]]:
    lines = command.split("\n")
    kept: list[str] = []
    bodies: list[tuple[str, str]] = []
    index = 0
    while index < len(lines):
        line = lines[index]
        kept.append(line)
        index += 1
        for match in HEREDOC_START.finditer(line):
            delimiter = match.group(2) or match.group(3) or match.group(4)
            body: list[str] = []
            while index < len(lines):
                candidate = (
                    lines[index].lstrip("\t") if match.group(1) else lines[index]
                )
                index += 1
                if candidate.rstrip() == delimiter:
                    break
                body.append(lines[index - 1])
            bodies.append((line[: match.start()], "\n".join(body)))
    return "\n".join(kept), bodies


def tokenize(command: str) -> list[str] | None:
    # A backslash-newline continues the command; it is not a separator.
    command = re.sub(r"\\\n", " ", command)
    lexer = shlex.shlex(command, posix=True, punctuation_chars=";&|()<>\n")
    lexer.whitespace = " \t\r"
    lexer.whitespace_split = True
    lexer.commenters = ""
    try:
        return list(lexer)
    except ValueError:
        return None


def substitutions(text: str) -> list[str]:
    """Return $(...) and backtick bodies outside single quotes."""
    found: list[str] = []
    index, single, double = 0, False, False
    while index < len(text):
        character = text[index]
        if character == "\\" and not single:
            index += 2
            continue
        if character == "'" and not double:
            single = not single
        elif character == '"' and not single:
            double = not double
        elif (
            not single
            and text.startswith("$(", index)
            and not text.startswith("$((", index)
        ):
            depth, cursor = 1, index + 2
            while cursor < len(text) and depth:
                depth += {"(": 1, ")": -1}.get(text[cursor], 0)
                cursor += 1
            found.append(
                text[index + 2 : cursor - 1] if depth == 0 else text[index + 2 :]
            )
            index = cursor
            continue
        elif not single and character == "`":
            end = text.find("`", index + 1)
            if end == -1:
                break
            found.append(text[index + 1 : end])
            index = end + 1
            continue
        index += 1
    return found


def simple_commands(tokens: list[str]) -> list[list[str]]:
    commands: list[list[str]] = []
    current: list[str] = []
    skip_next = False
    for token in tokens:
        if skip_next:
            skip_next = False
            continue
        if token and all(character in ";&|()<>\n" for character in token):
            if "<" in token or ">" in token:
                if current and current[-1].isdigit():
                    current.pop()
                skip_next = True
                continue
            if current:
                commands.append(current)
            current = []
            continue
        current.append(token)
    if current:
        commands.append(current)
    return commands


def strip_options(argv: list[str], value_options: set[str]) -> list[str]:
    index = 1
    while index < len(argv) and argv[index].startswith("-") and argv[index] != "--":
        option = argv[index].split("=", 1)[0]
        index += 2 if option in value_options and "=" not in argv[index] else 1
    if index < len(argv) and argv[index] == "--":
        index += 1
    return argv[index:]


def script_operand(argv: list[str]) -> str | None:
    """Return the script a shell or a path-invoked .sh file would run."""
    if Path(argv[0]).name in SHELLS:
        operands = [item for item in argv[1:] if not item.startswith("-")]
        return operands[0] if operands else None
    if "/" in argv[0] and argv[0].endswith(".sh"):
        return argv[0]
    return None


def attr_name(installable: str) -> str:
    name = installable.rsplit("#", 1)[-1].rsplit("/", 1)[-1]
    return name.split(".")[-1] or name


def unwrap(argv: list[str]) -> tuple[list[str], list[str]]:
    """Strip wrapper commands; return (argv, nested shell scripts)."""
    while argv:
        head = Path(argv[0]).name
        if argv[0] in RESERVED_WORDS:
            argv = argv[1:]
        elif argv[0] in {"for", "select"}:
            return [], []
        elif ASSIGNMENT.match(argv[0]):
            argv = argv[1:]
        elif head in SHELLS:
            for index, item in enumerate(argv[1:-1], start=1):
                if re.fullmatch(r"-[A-Za-z]*c[A-Za-z]*", item):
                    return [], [argv[index + 1]]
            return argv, []
        elif head == "eval":
            return [], [" ".join(argv[1:])]
        elif head in SIMPLE_WRAPPERS or head in WRAPPER_VALUE_OPTIONS:
            rest = strip_options(argv, WRAPPER_VALUE_OPTIONS.get(head, set()))
            if head == "env":
                while rest and ASSIGNMENT.match(rest[0]):
                    rest = rest[1:]
            elif head == "timeout" and rest:
                rest = rest[1:]
            elif head == "flock" and rest:
                rest = rest[1:]
                if rest[:1] in (["-c"], ["--command"]) and len(rest) > 1:
                    return [], [rest[1]]
            argv = rest
        elif head == "systemd-run":
            argv = (
                argv[argv.index("--") + 1 :]
                if "--" in argv
                else strip_options(argv, set())
            )
        elif head == "nix-shell":
            for option in ("--run", "--command"):
                if option in argv[:-1]:
                    return [], [argv[argv.index(option) + 1]]
            return argv, []
        elif head == "nix" and len(argv) > 2 and argv[1] in {"shell", "develop"}:
            for option in ("-c", "--command"):
                if option in argv:
                    argv = argv[argv.index(option) + 1 :]
                    break
            else:
                return argv, []
        elif head == "nix" and len(argv) > 2 and argv[1] == "run":
            positionals = [item for item in argv[2:] if not item.startswith("-")]
            if not positionals:
                return argv, []
            arguments = argv[argv.index("--") + 1 :] if "--" in argv else []
            argv = [attr_name(positionals[0]), *arguments]
        else:
            return argv, []
    return argv, []


def option_values(args: list[str], names: set[str]) -> list[str]:
    values: list[str] = []
    index = 0
    while index < len(args):
        item = args[index]
        name, separator, attached = item.partition("=")
        if name in names and separator:
            values.append(attached)
        elif item in names and index + 1 < len(args):
            values.append(args[index + 1])
            index += 1
        elif (
            len(item) > 2
            and item[0] == "-"
            and item[1] != "-"
            and item[:2] in names
            and not separator
        ):
            values.append(item[2:])
        index += 1
    return values


def has_option(args: list[str], names: set[str]) -> bool:
    return any(item.split("=", 1)[0] in names for item in args)


def positionals(args: list[str], value_options: set[str]) -> list[str]:
    found: list[str] = []
    index = 0
    while index < len(args):
        item = args[index]
        if item == "--":
            found.extend(args[index + 1 :])
            break
        if item.startswith("-") and len(item) > 1:
            if item in value_options:
                index += 1
        else:
            found.append(item)
        index += 1
    return found
