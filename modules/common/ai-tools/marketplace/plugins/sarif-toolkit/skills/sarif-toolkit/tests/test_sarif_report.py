from __future__ import annotations

import contextlib
import importlib.util
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).parents[1] / "scripts" / "sarif_report.py"
SPEC = importlib.util.spec_from_file_location("sarif_report", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
sarif_report = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = sarif_report
SPEC.loader.exec_module(sarif_report)


def fixture() -> dict[str, object]:
    return {
        "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
        "version": "2.1.0",
        "runs": [
            {
                "tool": {
                    "driver": {
                        "name": "Example Analyzer",
                        "semanticVersion": "1.2.3",
                        "rules": [
                            {"id": "R1", "defaultConfiguration": {"level": "error"}},
                            {"id": "R2"},
                        ],
                    }
                },
                "artifacts": [{"location": {"uri": "src/b.py"}}],
                "results": [
                    {
                        "ruleId": "R1",
                        "message": {"text": "First error"},
                        "locations": [
                            {
                                "physicalLocation": {
                                    "artifactLocation": {"uri": "src/a.py"},
                                    "region": {"startLine": 7},
                                }
                            }
                        ],
                    },
                    {
                        "ruleIndex": 1,
                        "level": "warning",
                        "message": {"text": "Second warning"},
                        "locations": [
                            {"physicalLocation": {"artifactLocation": {"index": 0}}}
                        ],
                    },
                ],
            },
            {
                "tool": {"driver": {"name": "Other Analyzer", "version": "4"}},
                "artifacts": [{"location": {"uri": "src/a.py"}}],
                "results": [
                    {
                        "ruleId": "R1",
                        "level": "note",
                        "message": {"markdown": "Third note"},
                        "locations": [
                            {
                                "physicalLocation": {
                                    "artifactLocation": {"uri": "src/a.py"}
                                }
                            }
                        ],
                    },
                    {"message": {"text": "Unclassified result"}},
                ],
            },
        ],
    }


def write_fixture(directory: Path) -> Path:
    path = directory / "input.sarif"
    path.write_text(json.dumps(fixture()), encoding="utf-8")
    return path


class SarifReportTests(unittest.TestCase):
    def test_report_covers_required_summary_fields(self) -> None:
        report = sarif_report.summarize(fixture())

        self.assertEqual(report["version"], "2.1.0")
        self.assertEqual(report["runs"], 2)
        self.assertEqual(report["results"], 4)
        self.assertEqual(report["artifacts"], 2)
        self.assertEqual(report["tools"][0]["name"], "Example Analyzer")
        self.assertEqual(report["top_rules"][0], {"rule_id": "R1", "count": 2})
        self.assertIn({"level": "error", "count": 1}, report["severities"])
        self.assertIn({"path": "src/a.py", "count": 2}, report["affected_paths"])
        self.assertEqual(report["representative_results"][0]["line"], 7)
        self.assertEqual(report["tools_omitted"], 0)
        self.assertEqual(report["severities_omitted"], 0)

    def test_report_bounds_tools_severities_and_scalar_values(self) -> None:
        long_value = "x" * 1000
        document = {
            "$schema": long_value,
            "version": long_value,
            "runs": [
                {
                    "tool": {"driver": {"name": f"tool-{index}-{long_value}"}},
                    "results": [
                        {
                            "ruleId": f"rule-{index}-{long_value}",
                            "level": f"severity-{index}-{long_value}",
                            "message": {"text": long_value},
                            "locations": [
                                {
                                    "physicalLocation": {
                                        "artifactLocation": {
                                            "uri": f"path-{index}-{long_value}"
                                        }
                                    }
                                }
                            ],
                        }
                    ],
                }
                for index in range(3)
            ],
        }

        report = sarif_report.summarize(
            document,
            top=1,
            representatives=1,
            maximum_tools=1,
            maximum_severities=1,
            maximum_value_chars=12,
        )

        self.assertEqual(report["tools_total"], 3)
        self.assertEqual(report["tools_omitted"], 2)
        self.assertTrue(report["tools_truncated"])
        self.assertEqual(report["severities_total"], 3)
        self.assertEqual(report["severities_omitted"], 2)
        self.assertTrue(report["severities_truncated"])
        self.assertEqual(report["top_rules_omitted"], 2)
        self.assertEqual(report["affected_paths_omitted"], 2)
        self.assertLessEqual(len(report["schema"]), 12)
        self.assertLessEqual(len(report["tools"][0]["name"]), 12)
        self.assertLessEqual(len(report["top_rules"][0]["rule_id"]), 12)
        self.assertLessEqual(len(report["affected_paths"][0]["path"]), 12)
        representative = report["representative_results"][0]
        self.assertTrue(
            all(
                len(representative[key]) <= 12
                for key in ("rule_id", "level", "path", "message")
            )
        )

    def test_report_mode_does_not_write_files(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            source = write_fixture(directory)
            stdout = io.StringIO()

            with contextlib.redirect_stdout(stdout):
                status = sarif_report.main([str(source), "--format", "json"])

            self.assertEqual(status, 0)
            self.assertEqual(json.loads(stdout.getvalue())["results"], 4)
            self.assertEqual(
                sorted(path.name for path in directory.iterdir()), ["input.sarif"]
            )

    def test_rule_split_names_are_stable_and_overwrite_requires_force(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            source = write_fixture(directory)
            output = directory / "split"
            document = sarif_report.load_sarif(source)

            first = sarif_report.write_split(
                source,
                document,
                strategy="rule",
                chunks=None,
                output_dir=output,
            )
            first_names = [item["path"] for item in first["files"]]
            self.assertEqual(len(first_names), 3)
            self.assertTrue(all(name.endswith(".sarif") for name in first_names))

            with self.assertRaises(sarif_report.SarifError):
                sarif_report.write_split(
                    source,
                    document,
                    strategy="rule",
                    chunks=None,
                    output_dir=output,
                )

            unknown = output / "keep.txt"
            unknown.write_text("keep", encoding="utf-8")
            second = sarif_report.write_split(
                source,
                document,
                strategy="rule",
                chunks=None,
                output_dir=output,
                force=True,
            )

            self.assertEqual([item["path"] for item in second["files"]], first_names)
            self.assertEqual(unknown.read_text(encoding="utf-8"), "keep")
            manifest = json.loads(
                (output / "manifest.json").read_text(encoding="utf-8")
            )
            self.assertEqual(manifest["results"], 4)
            self.assertEqual(sum(item["results"] for item in manifest["files"]), 4)

    def test_all_partition_strategies_are_deterministic(self) -> None:
        records = sarif_report.result_records(fixture())

        self.assertEqual(
            [key for key, _ in sarif_report.partition_records(records, "severity")],
            ["error", "none", "note", "warning"],
        )
        self.assertEqual(
            [key for key, _ in sarif_report.partition_records(records, "path")],
            ["<no-path>", "src/a.py", "src/b.py"],
        )
        balanced = sarif_report.partition_records(records, "balanced", 3)
        self.assertEqual([len(group) for _, group in balanced], [2, 1, 1])

        with self.assertRaises(sarif_report.SarifError):
            sarif_report.partition_records(records, "rule", 2)
        with self.assertRaises(sarif_report.SarifError):
            sarif_report.partition_records(records, "balanced", None)

    def test_force_refuses_unowned_filename_collision(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            source = write_fixture(directory)
            output = directory / "split"
            output.mkdir()
            document = sarif_report.load_sarif(source)
            records = sarif_report.result_records(document)
            key = sarif_report.partition_records(records, "rule")[0][0]
            collision = output / sarif_report.stable_filename(1, "rule", key)
            collision.write_text("unrelated", encoding="utf-8")

            with self.assertRaises(sarif_report.SarifError):
                sarif_report.write_split(
                    source,
                    document,
                    strategy="rule",
                    chunks=None,
                    output_dir=output,
                    force=True,
                )

            self.assertEqual(collision.read_text(encoding="utf-8"), "unrelated")
            self.assertFalse((output / "manifest.json").exists())

    def test_split_stdout_listing_is_bounded_but_manifest_is_complete(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            source = write_fixture(directory)
            output = directory / "split"
            report = sarif_report.write_split(
                source,
                sarif_report.load_sarif(source),
                strategy="rule",
                chunks=None,
                output_dir=output,
                maximum_report_files=1,
                maximum_value_chars=12,
            )

            self.assertEqual(report["files_total"], 3)
            self.assertEqual(report["files_omitted"], 2)
            self.assertTrue(report["files_truncated"])
            self.assertEqual(len(report["files"]), 1)
            self.assertNotIn("runs", report["files"][0])
            manifest = json.loads(
                (output / "manifest.json").read_text(encoding="utf-8")
            )
            self.assertEqual(len(manifest["files"]), 3)
            self.assertIn("runs", manifest["files"][0])

    def test_force_preflights_all_owned_paths_before_deleting_any(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary) / "split"
            output.mkdir()
            first = output / "0001-first.sarif"
            invalid = output / "0002-invalid.sarif"
            first.write_text("preserve", encoding="utf-8")
            invalid.mkdir()
            (output / "manifest.json").write_text(
                json.dumps(
                    {
                        "generated_by": sarif_report.GENERATED_BY,
                        "files": [
                            {"path": first.name},
                            {"path": invalid.name},
                        ],
                    }
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(sarif_report.SarifError, "non-file"):
                sarif_report.prepare_output_directory(
                    output, {first.name, invalid.name}, force=True
                )

            self.assertEqual(first.read_text(encoding="utf-8"), "preserve")
            self.assertTrue(invalid.is_dir())

    def test_split_documents_preserve_only_assigned_results(self) -> None:
        document = fixture()
        records = sarif_report.result_records(document)
        groups = sarif_report.partition_records(records, "rule")

        total = 0
        for _, group in groups:
            chunk = sarif_report.document_for_records(document, group)
            count = sum(len(run["results"]) for run in chunk["runs"])
            self.assertEqual(count, len(group))
            total += count

        self.assertEqual(total, 4)


if __name__ == "__main__":
    unittest.main()
