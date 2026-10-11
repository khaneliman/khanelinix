"""Run from an ignored build/cache directory:
python3 /path/to/repo/tests/package-runtime-regressions.py /path/to/locked/nixpkgs.

Requires Nix and access to its store. Builds only the tested wrappers and FFmpeg;
intercepts build-by-path's build drivers, not its Nix expression evaluation.
Audio fallback tests use generated media; only failure/interruption and
mkvpropedit discovery are injected, not successful FFmpeg remuxing.
"""

import importlib.util
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from unittest.mock import patch

PACKAGES = Path(__file__).resolve().parents[1] / "packages"
NIXPKGS = Path(sys.argv[1]).resolve()
NIX = shutil.which("nix")


def run(*args, **kwargs):
    return subprocess.run(
        args, check=True, text=True, capture_output=True, **kwargs
    ).stdout


expression = f"""
let
  pkgs = import {json.dumps(str(NIXPKGS))} {{}};
  trace = pkgs.callPackage {PACKAGES}/trace-symlink/package.nix {{}};
  which = pkgs.callPackage {PACKAGES}/trace-which/package.nix {{ trace-symlink = trace; }};
  title = pkgs.callPackage {PACKAGES}/ff-title/package.nix {{}};
in [ trace which title (pkgs.lib.getBin pkgs.ffmpeg) ]
"""
outputs = json.loads(
    run(NIX, "build", "--impure", "--no-link", "--json", "--expr", expression)
)
bins = [Path(path) / "bin" for p in outputs for path in p["outputs"].values()]
trace, which, title, ffmpeg = [
    next(p for p in bins if (p / name).is_file())
    for name in ("trace-symlink", "trace-which", "ff-title", "ffmpeg")
]

# Keep scratch under the caller's ignored build/cache directory, never /tmp.
with tempfile.TemporaryDirectory(prefix="package-regressions-", dir=Path.cwd()) as work:
    work = Path(work)
    env = dict(os.environ, TMPDIR=str(work))
    fixture = work / "nixpkgs"
    fixture.mkdir()
    (fixture / "default.nix").write_text(f"""
{{ system, config }}:
let
  lib = import {json.dumps(str(NIXPKGS / "lib"))};
  pkg = builtins.derivation {{
    name = "regression";
    inherit system;
    builder = "/unused";
    outputs = [ "out" "dev" ];
  }};
in {{
  inherit lib;
  direct = pkg;
  nested.singleton.only = pkg;
  nested.multiple = {{ first = pkg; second = pkg; ignored = null; failing = throw "skip"; }};
  empty = {{}};
  linkFarm = _: entries: entries;
}}
""")
    drivers = work / "drivers"
    drivers.mkdir()
    driver = drivers / "driver"
    driver.write_text(f"""#!{sys.executable}
import json, os, sys
args = sys.argv[1:]
if args[0:1] == ["eval"]:
    os.execv({NIX!r}, [{NIX!r}] + args)
file = args[args.index("--file") + 1]
fast = os.path.basename(sys.argv[0]) == "nix-fast-build"
if fast:
    assert args[args.index("--systems") + 1] == "x86_64-linux"
    assert "--dry-run" in args
apply = ('pkgs: builtins.mapAttrs (_: p: toString p) pkgs' if fast else
         'entries: map (p: {{ inherit (p) name; path = toString p.path; }}) entries')
os.execv({NIX!r}, [{NIX!r}, "eval", "--json", "--file", file, "--apply", apply])
""")
    driver.chmod(0o755)
    for name in ("nix", "nom", "nix-fast-build"):
        (drivers / name).symlink_to(driver)
    env["PATH"] = str(drivers) + os.pathsep + os.environ["PATH"]
    expected = json.loads(
        run(
            NIX,
            "eval",
            "--json",
            "--impure",
            "--expr",
            f"""
let p = (import {json.dumps(str(fixture))} {{ system = "x86_64-linux"; config = {{}}; }}).direct;
in {{ out = toString p.out; dev = toString p.dev; }}
""",
        )
    )
    for root, names in (
        ("direct", ["direct"]),
        ("nested.singleton", ["only"]),
        ("nested.multiple", ["first", "second"]),
        ("empty", []),
    ):
        wanted = {
            name + (".dev" if output == "dev" else ""): path
            for name in names
            for output, path in expected.items()
        }
        for fast in (False, True):
            args = ["bash", str(PACKAGES / "build-by-path/build-by-path.sh")]
            if fast:
                args.append("--fast")
            args += [str(fixture), root, "x86_64-linux"]
            if fast:
                args += ["--", "--dry-run"]
            result = run(*args, env=env)
            # nom discovery may print a status line before the evaluated result.
            result = json.loads(result.splitlines()[-1])
            if not fast:
                result = {p["name"]: p["path"] for p in result}
            assert result == wanted, (root, fast, result, wanted)
    print(
        "PASS build-by-path: direct, singleton, multi-entry, empty; both drivers; out/dev selection"
    )

    target = work / "target file"
    target.write_text("#!/bin/sh\nexit 0\n")
    target.chmod(0o755)
    relative = work / "relative"
    relative.symlink_to(target.name)
    absolute = work / "absolute"
    absolute.symlink_to(target)
    chain = work / "chain"
    chain.symlink_to(relative.name)
    for link, wanted in (
        (target, [target]),
        (relative, [relative, target]),
        (absolute, [absolute, target]),
        (chain, [chain, relative, target]),
    ):
        assert run(
            str(trace / "trace-symlink"), str(link), env=env
        ).splitlines() == list(map(str, wanted))
    parent = work / "parent"
    parent.symlink_to(work, target_is_directory=True)
    assert run(
        str(trace / "trace-symlink"), str(parent / target.name), env=env
    ).splitlines() == [str(parent / target.name), str(target)]
    env["PATH"] = str(work) + os.pathsep + os.environ["PATH"]
    assert run(str(which / "trace-which"), "chain", env=env).splitlines() == list(
        map(str, [chain, relative, target])
    )
    missing = subprocess.run(
        [str(trace / "trace-symlink"), str(work / "missing")],
        env=env,
        capture_output=True,
        check=False,
    )
    assert missing.returncode != 0
    print(
        "PASS trace-symlink/trace-which: regular, relative, absolute, chain, symlink parent, missing"
    )

    media = work / "multiple tracks.mkv"
    subtitles = work / "subtitles.srt"
    subtitles.write_text("1\n00:00:00,000 --> 00:00:00,500\nRegression\n")
    attachment = work / "attachment.txt"
    attachment.write_text("preserve attachment\n")
    ff = str(ffmpeg / "ffmpeg")
    probe = str(ffmpeg / "ffprobe")
    run(
        ff,
        "-v",
        "error",
        "-f",
        "lavfi",
        "-i",
        "color=size=16x16:duration=1",
        "-f",
        "lavfi",
        "-i",
        "sine=frequency=440:duration=1",
        "-f",
        "lavfi",
        "-i",
        "sine=frequency=880:duration=1",
        "-i",
        str(subtitles),
        "-map",
        "0",
        "-map",
        "1",
        "-map",
        "2",
        "-map",
        "3",
        "-c:v",
        "ffv1",
        "-c:a",
        "pcm_s16le",
        "-c:s",
        "srt",
        "-attach",
        str(attachment),
        "-metadata:s:t",
        "mimetype=text/plain",
        "-metadata:s:a:0",
        "language=eng",
        "-metadata:s:a:1",
        "language=fra",
        str(media),
    )

    def inspect():
        return json.loads(
            run(
                probe,
                "-v",
                "error",
                "-show_streams",
                "-show_data_hash",
                "sha256",
                "-show_format",
                "-of",
                "json",
                str(media),
            )
        )

    before = inspect()

    def packets():
        return json.loads(
            run(
                probe,
                "-v",
                "error",
                "-show_packets",
                "-show_data_hash",
                "sha256",
                "-show_entries",
                "packet=stream_index,data_hash",
                "-of",
                "json",
                str(media),
            )
        )

    payloads = packets()
    run(str(title / "ff-title"), str(media), "Regression title", env=env)
    after = inspect()
    assert [s["codec_type"] for s in before["streams"]] == [
        "video",
        "audio",
        "audio",
        "subtitle",
        "attachment",
    ]
    for key in ("codec_type", "codec_name", "extradata_hash", "disposition"):
        assert [s.get(key) for s in before["streams"]] == [
            s.get(key) for s in after["streams"]
        ], key

    # The Matroska muxer recomputes DURATION, including millisecond rounding.
    def tags(streams):
        return [
            {k: v for k, v in s.get("tags", {}).items() if k != "DURATION"}
            for s in streams
        ]

    assert tags(before["streams"]) == tags(after["streams"])
    assert packets() == payloads, "stream packet payloads changed"
    assert after["format"]["tags"]["title"] == "Regression title"
    assert not media.with_suffix(".tmp.mkv").exists()
    print(
        "PASS ff-title: video, two audio tracks, subtitle, attachment, tags and packet hashes preserved; title updated"
    )

    # Import only the tool body; force the fallback without mkvpropedit or PATH
    # discovery, but execute the locked FFmpeg/ffprobe on generated media.
    spec = importlib.util.spec_from_file_location(
        "audio_stream_fixer", PACKAGES / "audio-stream-fixer/audio-stream-fixer.py"
    )
    fixer = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(fixer)
    run(
        ff,
        "-v",
        "error",
        "-i",
        str(media),
        "-map",
        "0",
        "-c",
        "copy",
        "-metadata:s:a:0",
        "language=fra",
        "-metadata:s:a:1",
        "language=eng",
        "-disposition:a:0",
        "default+visual_impaired",
        "-disposition:a:1",
        "hearing_impaired",
        str(work / "audio base.mkv"),
    )
    shutil.copyfile(work / "audio base.mkv", media)
    before = inspect()
    payloads = packets()
    sentinel = Path(str(media) + ".tmp.mkv")
    sentinel.write_bytes(b"unrelated existing content")
    original_run = subprocess.run

    def ffmpeg_run(command, **kwargs):
        command = list(command)
        command[0] = {"ffmpeg": ff, "ffprobe": probe}[command[0]]
        return original_run(command, **kwargs)

    with (
        patch.object(fixer.shutil, "which", return_value=None),
        patch.object(fixer.subprocess, "run", side_effect=ffmpeg_run),
    ):
        item = fixer.analyze_file(str(media), [])
        assert item["status"] == "fixable", item
        assert fixer.apply_fix(item)
    after = inspect()
    expected = [dict(s["disposition"]) for s in before["streams"]]
    expected[item["current_index"]]["default"] = 0
    expected[item["eng_index"]]["default"] = 1
    assert [s["disposition"] for s in after["streams"]] == expected, (
        "only the two default flags may change",
        expected,
        after["streams"],
    )
    for key in ("codec_type", "codec_name", "extradata_hash"):
        assert [s.get(key) for s in before["streams"]] == [
            s.get(key) for s in after["streams"]
        ], key
    assert tags(before["streams"]) == tags(after["streams"])
    assert packets() == payloads, "stream packet payloads changed"
    assert (
        sentinel.exists() and sentinel.read_bytes() == b"unrelated existing content"
    ), "predictable temporary file sentinel was overwritten or deleted"
    assert not list(work.glob(".audio-stream-fixer-*"))
    print(
        "PASS audio fixer: only default flags changed; streams, tags, packets and temp sentinel preserved"
    )

    for failure in (
        subprocess.CalledProcessError(1, ["ffmpeg"]),
        OSError("cannot execute"),
        KeyboardInterrupt(),
    ):
        original = media.read_bytes()
        entries = set(work.iterdir())

        def fail(command, failure=failure, **kwargs):
            Path(command[-1]).write_bytes(b"partial output")
            raise failure

        with (
            patch.object(fixer.shutil, "which", return_value=None),
            patch.object(fixer.subprocess, "run", side_effect=fail),
        ):
            try:
                result = fixer.apply_fix(item)
            except KeyboardInterrupt:
                assert isinstance(failure, KeyboardInterrupt)
            else:
                assert not isinstance(failure, KeyboardInterrupt)
                assert result is False
        assert media.read_bytes() == original
        assert (
            sentinel.exists() and sentinel.read_bytes() == b"unrelated existing content"
        ), "predictable temporary file sentinel was overwritten or deleted"
        assert set(work.iterdir()) == entries, "partial staging survived failure"
    print(
        "PASS audio fixer: command failure, OS error and interruption preserve original and clean staging"
    )

    original = media.read_bytes()
    entries = set(work.iterdir())
    with (
        patch.object(fixer.shutil, "which", return_value=None),
        patch.object(fixer.subprocess, "run", side_effect=ffmpeg_run),
        patch.object(fixer.os, "replace", side_effect=OSError("cannot publish")),
    ):
        assert fixer.apply_fix(item) is False
    assert media.read_bytes() == original
    assert set(work.iterdir()) == entries
    assert sentinel.read_bytes() == b"unrelated existing content"
    print("PASS audio fixer: publication failure preserves source and cleans staging")
