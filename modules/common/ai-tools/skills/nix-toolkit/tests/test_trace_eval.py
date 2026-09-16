from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path
from typing import Any

SCRIPT = Path(__file__).parents[1] / "scripts" / "trace_eval.py"
SPEC = importlib.util.spec_from_file_location("trace_eval", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
trace_eval = importlib.util.module_from_spec(SPEC)
# Register before executing: dataclasses resolve their module from sys.modules.
sys.modules[SPEC.name] = trace_eval
SPEC.loader.exec_module(trace_eval)


# Trimmed from a real `nix eval --show-trace` run on a module whose `imports`
# list reads `config`.
RECURSION_TRACE = """\
error:
       … while calling the 'catAttrs' builtin
         at «github:NixOS/nixpkgs/ef34387ddd751e1ab8857adf4676492d32eb24ec?narHash=sha256-abc%3D»/lib/modules.nix:529:37:
          528|       imports
          529|         ++ catAttrs "imports" modules
             |                                     ^

       … from call site

       … while evaluating the attribute 'imports'
         at /project/broken.nix:7:9:
            7|         imports = lib.optional config.demo.enable ./unused.nix;
             |         ^

       … in the left operand of the AND (&&) operator

       … from call site

       … while evaluating the module argument `config' in ":anon-1":

       … if you get an infinite recursion here, you probably reference `config` in `imports`.

       error: infinite recursion encountered
"""


class ParseTraceTest(unittest.TestCase):
    trace: Any

    def setUp(self) -> None:
        self.trace = trace_eval.parse_trace(RECURSION_TRACE)

    def test_collects_the_terminal_error(self) -> None:
        self.assertIn("infinite recursion encountered", self.trace.errors)

    def test_bare_error_header_is_not_recorded(self) -> None:
        self.assertNotIn("", self.trace.errors)

    def test_attaches_locations_to_their_frame(self) -> None:
        located = [f for f in self.trace.frames if f.location is not None]
        self.assertTrue(
            any(f.location.endswith("/project/broken.nix:7:9") for f in located)
        )

    def test_source_excerpts_are_separated_from_frames(self) -> None:
        self.assertTrue(self.trace.source_lines)
        self.assertTrue(all(frame.context for frame in self.trace.frames))


class ClassificationTest(unittest.TestCase):
    def test_positional_context_is_not_a_hint(self) -> None:
        for context in (
            "from call site",
            "in the left operand of the AND (&&) operator",
        ):
            self.assertFalse(trace_eval.Frame(context=context).is_hint)

    def test_advice_is_a_hint(self) -> None:
        frame = trace_eval.Frame(context="if you get an infinite recursion here")
        self.assertTrue(frame.is_hint)

    def test_while_frames_are_calls(self) -> None:
        frame = trace_eval.Frame(context="while evaluating the attribute 'imports'")
        self.assertTrue(frame.is_call)
        self.assertFalse(frame.is_hint)


class ShortenTest(unittest.TestCase):
    def test_drops_store_prefix(self) -> None:
        path = "/nix/store/" + "a" * 32 + "-source/modules/demo.nix:3:1"
        self.assertEqual(trace_eval.shorten(path), "modules/demo.nix:3:1")

    def test_collapses_flake_reference(self) -> None:
        path = (
            "«github:NixOS/nixpkgs/" + "e" * 40 + "?narHash=sha256-abc%3D»"
            "/lib/modules.nix:268:13"
        )
        self.assertEqual(
            trace_eval.shorten(path),
            "github:NixOS/nixpkgs/eeeeeeee/lib/modules.nix:268:13",
        )

    def test_leaves_plain_paths_alone(self) -> None:
        self.assertEqual(
            trace_eval.shorten("/project/broken.nix:7:9"), "/project/broken.nix:7:9"
        )


class ReportTest(unittest.TestCase):
    def build(self, root: Path) -> dict[str, Any]:
        return trace_eval.build_report(
            trace_eval.parse_trace(RECURSION_TRACE), root, frames=2
        )

    def test_identifies_the_project_frame(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "broken.nix").write_text("{ }")
            trace = trace_eval.parse_trace(
                RECURSION_TRACE.replace("/project/", f"{root}/")
            )
            report = trace_eval.build_report(trace, root, frames=2)

        self.assertEqual(len(report["projectFrames"]), 1)
        self.assertEqual(
            report["projectFrames"][0]["context"],
            "while evaluating the attribute 'imports'",
        )

    def test_reports_no_project_frames_when_nothing_matches(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            report = self.build(Path(directory))
        self.assertEqual(report["projectFrames"], [])

    def test_keeps_only_the_requested_innermost_frames(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            report = self.build(Path(directory))
        self.assertEqual(len(report["innermostFrames"]), 2)
        self.assertGreater(report["frameCount"], 2)
        self.assertEqual(
            report["innermostFrames"][-1]["context"],
            'while evaluating the module argument `config\' in ":anon-1":',
        )

    def test_deduplicates_hints(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            report = self.build(Path(directory))
        self.assertEqual(len(report["hints"]), len(set(report["hints"])))
        self.assertTrue(
            any("reference `config` in `imports`" in hint for hint in report["hints"])
        )


class ResolveCommandTest(unittest.TestCase):
    def resolve(self, argv: list[str]) -> list[str]:
        return trace_eval.resolve_command(trace_eval.parse_arguments(argv))

    def test_builds_a_default_eval_command(self) -> None:
        command = self.resolve([".#foo"])
        self.assertEqual(command[:3], ["nix", "eval", "--show-trace"])
        self.assertEqual(command[-1], ".#foo")

    def test_passes_an_explicit_command_through(self) -> None:
        # argparse consumes the first `--`, so the leading word arrives
        # separately and must be put back.
        command = self.resolve(["--", "nix", "build", ".#foo"])
        self.assertEqual(command, ["nix", "build", ".#foo"])

    def test_requires_a_target(self) -> None:
        with self.assertRaises(trace_eval.TraceEvalError):
            self.resolve([])


if __name__ == "__main__":
    unittest.main()
