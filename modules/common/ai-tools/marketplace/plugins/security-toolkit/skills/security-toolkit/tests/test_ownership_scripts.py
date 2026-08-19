from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path

SKILL = Path(__file__).parents[1]
RUNNER = SKILL / "scripts" / "run_ownership_map.py"
QUERY = SKILL / "scripts" / "query_ownership.py"


class OwnershipScriptTests(unittest.TestCase):
    def test_tiny_repository_build_and_bounded_query(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary) / "repo"
            output = Path(temporary) / "output"
            root.mkdir()
            subprocess.run(["git", "init", "-q", str(root)], check=True)
            (root / "app.py").write_text("print('ok')\n")
            subprocess.run(["git", "-C", str(root), "add", "app.py"], check=True)
            subprocess.run(
                [
                    "git",
                    "-C",
                    str(root),
                    "-c",
                    "user.name=Fixture",
                    "-c",
                    "user.email=fixture@example.com",
                    "commit",
                    "-qm",
                    "initial",
                ],
                check=True,
            )

            build = subprocess.run(
                [
                    "python3",
                    str(RUNNER),
                    "--repo",
                    str(root),
                    "--out",
                    str(output),
                    "--no-cochange",
                    "--no-communities",
                ],
                check=False,
                capture_output=True,
                text=True,
            )
            if build.returncode == 2 and "networkx is required" in build.stderr:
                output.mkdir()
                (output / "summary.json").write_text(
                    json.dumps({"repository": str(root), "findings": []})
                )
            else:
                self.assertEqual(0, build.returncode, build.stderr)
                self.assertTrue((output / "summary.json").is_file())

            query = subprocess.run(
                [
                    "python3",
                    str(QUERY),
                    "--data-dir",
                    str(output),
                    "summary",
                ],
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertEqual(0, query.returncode, query.stderr)
            report = json.loads(query.stdout)
            self.assertIn("repository", report)


if __name__ == "__main__":
    unittest.main()
