from __future__ import annotations

import importlib.util
import io
import json
import subprocess
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

SCRIPT = Path(__file__).parents[1] / "scripts" / "module_graph.py"
SPEC = importlib.util.spec_from_file_location("module_graph", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
module_graph = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = module_graph
SPEC.loader.exec_module(module_graph)


SAMPLE_GRAPH = [
    {
        "file": "/nix/store/abcdefghijklmnopqrstuvwxyz123456-source/modules/nixos/default.nix",
        "disabled": False,
        "imports": [
            {
                "file": "/nix/store/abcdefghijklmnopqrstuvwxyz123456-source/modules/nixos/services/ssh.nix",
                "disabled": False,
                "imports": [],
            },
            {
                "file": "/nix/store/abcdefghijklmnopqrstuvwxyz123456-source/modules/nixos/obsolete.nix",
                "disabled": True,
                "imports": [
                    {
                        "file": "/project/custom/leaf.nix",
                        "disabled": False,
                        "imports": [],
                    }
                ],
            },
        ],
    }
]


class StripStorePrefixTest(unittest.TestCase):
    def test_strips_nix_store_prefix(self) -> None:
        path = "/nix/store/11111111111111111111111111111111-source/modules/core.nix"
        self.assertEqual(module_graph.strip_store_prefix(path), "modules/core.nix")

    def test_preserves_plain_path(self) -> None:
        path = "/project/modules/core.nix"
        self.assertEqual(module_graph.strip_store_prefix(path), path)

    def test_preserves_store_path_without_trailing_slash(self) -> None:
        path = "/nix/store/11111111111111111111111111111111-source"
        self.assertEqual(module_graph.strip_store_prefix(path), path)


class FlattenTest(unittest.TestCase):
    def test_empty_graph(self) -> None:
        self.assertEqual(list(module_graph.flatten([])), [])

    def test_flatten_preserves_order_and_depth_chains(self) -> None:
        nodes = list(module_graph.flatten(SAMPLE_GRAPH))
        self.assertEqual(len(nodes), 4)

        root = nodes[0]
        self.assertEqual(root.file, "modules/nixos/default.nix")
        self.assertFalse(root.disabled)
        self.assertEqual(root.ancestors, ())

        ssh = nodes[1]
        self.assertEqual(ssh.file, "modules/nixos/services/ssh.nix")
        self.assertFalse(ssh.disabled)
        self.assertEqual(ssh.ancestors, ("modules/nixos/default.nix",))

        obsolete = nodes[2]
        self.assertEqual(obsolete.file, "modules/nixos/obsolete.nix")
        self.assertTrue(obsolete.disabled)
        self.assertEqual(obsolete.ancestors, ("modules/nixos/default.nix",))

        leaf = nodes[3]
        self.assertEqual(leaf.file, "/project/custom/leaf.nix")
        self.assertFalse(leaf.disabled)
        self.assertEqual(
            leaf.ancestors,
            ("modules/nixos/default.nix", "modules/nixos/obsolete.nix"),
        )


class BuildReportTest(unittest.TestCase):
    nodes: list[module_graph.Node]

    def setUp(self) -> None:
        self.nodes = list(module_graph.flatten(SAMPLE_GRAPH))

    def test_unfiltered_report(self) -> None:
        report = module_graph.build_report(
            self.nodes, pattern=None, show_disabled=False
        )
        self.assertEqual(report["totalNodes"], 4)
        self.assertEqual(report["distinctFiles"], 4)
        self.assertEqual(report["matchCount"], 4)
        self.assertIsNone(report["query"]["pattern"])
        self.assertFalse(report["query"]["disabledOnly"])

    def test_pattern_matching(self) -> None:
        report = module_graph.build_report(
            self.nodes, pattern=r"services/.*\.nix", show_disabled=False
        )
        self.assertEqual(report["matchCount"], 1)
        self.assertEqual(report["matches"][0]["file"], "modules/nixos/services/ssh.nix")
        self.assertEqual(
            report["matches"][0]["importedBy"], ["modules/nixos/default.nix"]
        )
        self.assertEqual(report["matches"][0]["depth"], 1)

    def test_disabled_only_filter(self) -> None:
        report = module_graph.build_report(self.nodes, pattern=None, show_disabled=True)
        self.assertEqual(report["matchCount"], 1)
        self.assertTrue(report["matches"][0]["disabled"])
        self.assertEqual(report["matches"][0]["file"], "modules/nixos/obsolete.nix")

    def test_no_matches_returns_empty_list(self) -> None:
        report = module_graph.build_report(
            self.nodes, pattern=r"nonexistent", show_disabled=False
        )
        self.assertEqual(report["matchCount"], 0)
        self.assertEqual(report["matches"], [])


class FormatReportTest(unittest.TestCase):
    nodes: list[module_graph.Node]

    def setUp(self) -> None:
        self.nodes = list(module_graph.flatten(SAMPLE_GRAPH))

    def test_format_shows_matches_and_depth(self) -> None:
        report = module_graph.build_report(
            self.nodes, pattern=None, show_disabled=False
        )
        output = module_graph.format_report(report, limit=40)
        self.assertIn("graph nodes:    4", output)
        self.assertIn("distinct files: 4", output)
        self.assertIn("matches:        4", output)
        self.assertIn("modules/nixos/obsolete.nix  (depth 1)  [disabled]", output)
        self.assertIn("imported by modules/nixos/default.nix", output)

    def test_format_respects_limit(self) -> None:
        report = module_graph.build_report(
            self.nodes, pattern=None, show_disabled=False
        )
        output = module_graph.format_report(report, limit=2)
        self.assertIn("... 2 more (raise --limit)", output)

    def test_empty_matches_messages(self) -> None:
        empty_disabled = module_graph.build_report(
            self.nodes, pattern=r"services", show_disabled=True
        )
        out_disabled = module_graph.format_report(empty_disabled, limit=40)
        self.assertIn("No module in the graph was disabled.", out_disabled)

        empty_graph = module_graph.build_report([], pattern=None, show_disabled=False)
        out_empty = module_graph.format_report(empty_graph, limit=40)
        self.assertIn("The graph is empty.", out_empty)

        empty_pattern = module_graph.build_report(
            self.nodes, pattern=r"nomatch", show_disabled=False
        )
        out_pattern = module_graph.format_report(empty_pattern, limit=40)
        self.assertIn("No module in the graph matched.", out_pattern)
        self.assertIn("A file absent here was never imported", out_pattern)


class EvaluateGraphTest(unittest.TestCase):
    def test_successful_evaluation(self) -> None:
        with patch("subprocess.run") as mock_run:
            mock_run.return_value = subprocess.CompletedProcess(
                args=[], returncode=0, stdout=json.dumps(SAMPLE_GRAPH), stderr=""
            )
            data = module_graph.evaluate_graph(".#test")
            self.assertEqual(len(data), 1)
            self.assertEqual(data[0]["file"], SAMPLE_GRAPH[0]["file"])

    def test_evaluation_failure_raises(self) -> None:
        with (
            patch("subprocess.run") as mock_run,
            patch("sys.stderr", new_callable=io.StringIO),
        ):
            mock_run.return_value = subprocess.CompletedProcess(
                args=[], returncode=1, stdout="", stderr="error: undefined attribute"
            )
            with self.assertRaisesRegex(
                module_graph.ModuleGraphError, "evaluation failed"
            ):
                module_graph.evaluate_graph(".#nonexistent")

    def test_missing_nix_command_raises(self) -> None:
        with (
            patch("subprocess.run", side_effect=FileNotFoundError("nix not found")),
            self.assertRaisesRegex(module_graph.ModuleGraphError, "could not run nix"),
        ):
            module_graph.evaluate_graph(".#test")


class MainCliTest(unittest.TestCase):
    def test_exit_0_on_matches(self) -> None:
        with (
            patch.object(module_graph, "evaluate_graph", return_value=SAMPLE_GRAPH),
            patch("sys.stdout", new_callable=io.StringIO) as mock_out,
        ):
            code = module_graph.main([".#host", "services"])
            self.assertEqual(code, 0)
            self.assertIn("modules/nixos/services/ssh.nix", mock_out.getvalue())

    def test_exit_0_on_json_output(self) -> None:
        with (
            patch.object(module_graph, "evaluate_graph", return_value=SAMPLE_GRAPH),
            patch("sys.stdout", new_callable=io.StringIO) as mock_out,
        ):
            code = module_graph.main([".#host", "--json"])
            self.assertEqual(code, 0)
            data = json.loads(mock_out.getvalue())
            self.assertEqual(data["matchCount"], 4)

    def test_exit_1_when_no_modules_match(self) -> None:
        with (
            patch.object(module_graph, "evaluate_graph", return_value=SAMPLE_GRAPH),
            patch("sys.stdout", new_callable=io.StringIO),
        ):
            code = module_graph.main([".#host", "nonexistent_pattern"])
            self.assertEqual(code, 1)

    def test_exit_2_on_invalid_regex(self) -> None:
        with patch("sys.stderr", new_callable=io.StringIO) as mock_err:
            code = module_graph.main([".#host", "[invalid regex"])
            self.assertEqual(code, 2)
            self.assertIn("error: invalid pattern", mock_err.getvalue())

    def test_exit_3_on_eval_error(self) -> None:
        with (
            patch.object(
                module_graph,
                "evaluate_graph",
                side_effect=module_graph.ModuleGraphError("eval failure"),
            ),
            patch("sys.stderr", new_callable=io.StringIO) as mock_err,
        ):
            code = module_graph.main([".#broken"])
            self.assertEqual(code, 3)
            self.assertIn("eval failure", mock_err.getvalue())


if __name__ == "__main__":
    unittest.main()
