"""Run: python3 tests/terminal-data-regressions.py /locked/nixpkgs ignored-scratch-dir.

Exercises built hook scripts and a Go template using the pinned lazygit Quote
implementation. Git is an argv recorder, so no real commits are made.
"""

import concurrent.futures
import json
import os
import pathlib
import re
import subprocess
import sys
import tempfile

root = pathlib.Path(__file__).resolve().parent.parent
nixpkgs = pathlib.Path(sys.argv[1]).resolve()
scratch = pathlib.Path(sys.argv[2]).resolve()
scratch.mkdir(parents=True, exist_ok=True)
scratch = pathlib.Path(tempfile.mkdtemp(prefix="terminal-data-", dir=scratch))
data_home = scratch / "data home"
expression = (
    f"import {root / 'tests/terminal-data-regressions.nix'} "
    f"{{ nixpkgs = builtins.toPath {json.dumps(str(nixpkgs))}; "
    f"dataHome = {json.dumps(str(data_home))}; }}"
)
subprocess.run(
    [
        "nix",
        "build",
        "--impure",
        "--no-link",
        "--expr",
        f"({expression}).scripts ++ ({expression}).dependencies",
    ],
    check=True,
)
rendered = json.loads(
    subprocess.check_output(
        ["nix", "eval", "--impure", "--json", "--expr", f"({expression}).rendered"],
        text=True,
    )
)
(scratch / "rendered.json").write_text(json.dumps(rendered, indent=2))

# Override the clock in the actual generated scripts' runtime PATH, ensuring
# collision tests cannot pass merely by crossing a wall-clock second.
clock = scratch / "clock"
clock.mkdir(exist_ok=True)
(clock / "date").write_text('#!/bin/sh\nprintf "%s\\n" "20261010-120000"\n')
(clock / "date").chmod(0o755)
for name in ("pre", "post"):
    script = pathlib.Path(rendered[name]).read_text()
    lines = script.splitlines()
    lines.insert(
        next(i for i, line in enumerate(lines) if line.startswith("export PATH=")) + 1,
        f"export PATH={json.dumps(str(clock))}:$PATH",
    )
    (scratch / f"{name}.sh").write_text("\n".join(lines) + "\n")

backup_root = data_home / "claude-code/context-backups"


def invoke(name, session, **fields):
    subprocess.run(
        ["bash", str(scratch / f"{name}.sh")],
        input=json.dumps({"session_id": session, **fields}),
        text=True,
        cwd=scratch,
        check=True,
    )


def parallel(name, sessions, **fields):
    with concurrent.futures.ThreadPoolExecutor() as pool:
        list(
            pool.map(lambda session: invoke(name, session, **fields[session]), sessions)
        )


sessions = ["session-a", "session-b"]
fields = {}
for session in sessions:
    transcript = scratch / f"{session}.jsonl"
    transcript.write_text(f"transcript for {session}\n")
    fields[session] = {"transcript_path": str(transcript), "trigger": "manual"}
parallel("pre", sessions, **fields)
markers = {session: backup_root / f".latest-{session}" for session in sessions}
directories = {
    session: pathlib.Path(marker.read_text().strip())
    for session, marker in markers.items()
}
assert len(set(directories.values())) == 2, directories
parallel(
    "post",
    sessions,
    **{
        session: {"compact_summary": f"summary for {session}", "trigger": "manual"}
        for session in sessions
    },
)
for session, directory in directories.items():
    assert (directory / "transcript.jsonl").read_text() == f"transcript for {session}\n"
    assert (directory / "compact-summary.txt").read_text() == f"summary for {session}\n"
    assert f"Session ID: {session}" in (directory / "metadata.txt").read_text()
    assert "Post-compact trigger: manual" in (directory / "metadata.txt").read_text()
    assert not markers[session].exists()
# Separate cycles from the same session also need different directories.
invoke("pre", "session-a", **fields["session-a"])
repeated = pathlib.Path(markers["session-a"].read_text().strip())
assert repeated != directories["session-a"]
invoke("post", "session-a", compact_summary="next summary")
assert (
    directories["session-a"] / "compact-summary.txt"
).read_text() == "summary for session-a\n"
# PostCompact may run without a PreCompact marker in custom workflows.
old_dirs = set(backup_root.glob("compact-*"))
parallel(
    "post",
    sessions,
    **{session: {"compact_summary": f"fallback {session}"} for session in sessions},
)
fallbacks = set(backup_root.glob("compact-*")) - old_dirs
assert len(fallbacks) == 2
assert {(directory / "compact-summary.txt").read_text() for directory in fallbacks} == {
    f"fallback {session}\n" for session in sessions
}
print(
    "PASS: concurrent pre/post pairing, repeated session, custom PostCompact fallback"
)

# Compile the exact POSIX Quote body from the supplied pinned lazygit source,
# not a Python imitation of its Go-template filter.
source = pathlib.Path(rendered["lazygitSource"])
quote_source = (source / "pkg/commands/oscommands/cmd_obj_builder.go").read_text()
body = re.search(
    r'func \(self \*CmdObjBuilder\) Quote\(message string\) string \{.*?\n\t(message = strings.NewReplacer\(.*?\n\treturn `"` \+ message \+ `"`)\n}',
    quote_source,
    re.DOTALL,
).group(1)
assert (
    '"quote":      self.c.OS().Quote'
    in (source / "pkg/gui/services/custom_commands/handler_creator.go").read_text()
)
helper = scratch / "render.go"
helper.write_text(
    'package main\nimport ("os"; "strings"; "encoding/json"; "text/template")\nfunc quote(message string) string {\n'
    + body
    + '\n}\nfunc main() {\nvar input struct { Template string; Form map[string]string }; if err := json.NewDecoder(os.Stdin).Decode(&input); err != nil { panic(err) }; t, err := template.New("commit").Funcs(template.FuncMap{"quote": quote}).Parse(input.Template); if err != nil { panic(err) }; if err := t.Execute(os.Stdout, input); err != nil { panic(err) }\n}\n'
)
helper_exe = scratch / "render-template"
env = os.environ | {"GOCACHE": str(scratch / "go-cache"), "GOTOOLCHAIN": "local"}
subprocess.run(
    [rendered["go"], "build", "-o", str(helper_exe), str(helper)], env=env, check=True
)
recorder = scratch / "bin"
recorder.mkdir(exist_ok=True)
(recorder / "git").write_text(
    f"#!{sys.executable}\nimport json, os, sys\nwith open(os.environ['ARGV_FILE'], 'w') as stream: json.dump(sys.argv[1:], stream)\n"
)
(recorder / "git").chmod(0o755)
argv_file = scratch / "argv.json"
for form in [
    {
        "Type": "fix",
        "Scope": "",
        "Breaking": "",
        "Message": "don't split this",
        "Body": "",
    },
    {
        "Type": "feat",
        "Scope": "parser",
        "Breaking": "!",
        "Message": 'keep "quotes" \\ and $HOME $(exit 19) `exit 20`; *\nnext line',
        "Body": 'reason\'s "quoted"\nsecond line',
    },
    {
        "Type": "fix'",
        "Scope": "scope'$(exit 21)",
        "Breaking": "!",
        "Message": "apostrophe's",
        "Body": "$(exit 22) `exit 23` \\",
    },
]:
    command = subprocess.check_output(
        [str(helper_exe)],
        input=json.dumps({"Template": rendered["commit"], "Form": form}),
        text=True,
    )
    subprocess.run(
        ["bash", "-c", command],
        env=env | {"PATH": f"{recorder}:{env['PATH']}", "ARGV_FILE": str(argv_file)},
        cwd=scratch,
        check=True,
    )
    subject = (
        form["Type"]
        + (f"({form['Scope']})" if form["Scope"] else "")
        + form["Breaking"]
        + ": "
        + form["Message"]
    )
    expected = ["commit", "--message", subject] + (
        ["--message", form["Body"]] if form["Body"] else []
    )
    assert json.loads(argv_file.read_text()) == expected
print("PASS: complete Go-template subject/body survive as exact shell argv")
