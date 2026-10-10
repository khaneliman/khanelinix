import contextlib
import importlib.util
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SCRIPT_PATH = (
    Path(sys.argv.pop(1))
    if len(sys.argv) > 1
    else Path(__file__).with_name("closure-analyzer.py")
)
spec = importlib.util.spec_from_file_location("closure", SCRIPT_PATH)
closure = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = closure
spec.loader.exec_module(closure)

STORE_PATH = "/nix/store/0123456789abcdfghijklmnpqrsvwxyz-example-1.0"


class AnalysisTests(unittest.TestCase):
    def test_nix_base32_names_and_non_hash_prefixes(self):
        analyzer = closure.ClosureAnalyzer("target")
        self.assertEqual(analyzer.extract_package_name(STORE_PATH), "example-1.0")
        for prefix in ("e" * 32, "o" * 32, "t" * 32, "u" * 32, "0" * 31, "0" * 33):
            name = prefix + "-example-1.0"
            self.assertEqual(analyzer.extract_package_name("/nix/store/" + name), name)

    def test_main_compares_previous_then_saves_current(self):
        for mode in ([], ["--json"]):
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as directory:
                analyzer = closure.ClosureAnalyzer("target", cache_dir=Path(directory))
                with patch.object(
                    analyzer,
                    "get_closure_info",
                    return_value=([(STORE_PATH, 1024**3, 1024**3)], 1024**3),
                ):
                    analyzer.save_analysis_cache(analyzer.analyze_closure(quiet=True))
                for size in (2, 3):
                    output = io.StringIO()
                    with (
                        patch.object(closure, "ClosureAnalyzer", return_value=analyzer),
                        patch.object(
                            analyzer,
                            "get_closure_info",
                            return_value=(
                                [(STORE_PATH, size * 1024**3, size * 1024**3)],
                                size * 1024**3,
                            ),
                        ),
                        patch.object(
                            sys, "argv", ["closure", "target", "--no-build", *mode]
                        ),
                        contextlib.redirect_stdout(output),
                    ):
                        closure.main()
                    if mode:
                        data = json.loads(output.getvalue())
                        self.assertEqual(
                            data["comparison"]["previous_size_gb"], size - 1
                        )
                        self.assertEqual(data["comparison"]["size_change_gb"], 1)
                    else:
                        self.assertIn(
                            f"Previous size: {size - 1:.2f} GB", output.getvalue()
                        )
                        self.assertIn("increased by 1.00 GB", output.getvalue())
                    self.assertEqual(
                        analyzer.load_analysis_cache()["total_size_gb"], size
                    )

    def test_no_cache_first_run_and_failed_report(self):
        with tempfile.TemporaryDirectory() as directory:
            analyzer = closure.ClosureAnalyzer("target", cache_dir=Path(directory))
            output = io.StringIO()
            info = ([(STORE_PATH, 1024**3, 1024**3)], 1024**3)
            with (
                patch.object(closure, "ClosureAnalyzer", return_value=analyzer),
                patch.object(analyzer, "get_closure_info", return_value=info),
                patch.object(
                    sys,
                    "argv",
                    ["closure", "target", "--no-build", "--json", "--no-cache"],
                ),
                contextlib.redirect_stdout(output),
            ):
                closure.main()
            self.assertNotIn("comparison", json.loads(output.getvalue()))
            self.assertIsNone(analyzer.load_analysis_cache())
            with (
                patch.object(closure, "ClosureAnalyzer", return_value=analyzer),
                patch.object(analyzer, "get_closure_info", return_value=info),
                patch.object(
                    sys,
                    "argv",
                    [
                        "closure",
                        "target",
                        "--no-build",
                        "--output",
                        str(Path(directory, "missing/report")),
                    ],
                ),
                contextlib.redirect_stdout(io.StringIO()),
                self.assertRaises(OSError),
            ):
                closure.main()
            self.assertIsNone(analyzer.load_analysis_cache())


if __name__ == "__main__":
    unittest.main()
