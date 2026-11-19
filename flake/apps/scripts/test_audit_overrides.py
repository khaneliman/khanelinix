import contextlib
import io
import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import audit_overrides as auditor

LOCK = {
    "root": "root",
    "nodes": {
        "root": {"inputs": {"nixpkgs": "linux", "nixpkgs-unstable": "darwin"}},
        "linux": {"locked": {"rev": "linux-rev", "narHash": "linux-hash"}},
        "darwin": {"locked": {"rev": "darwin-rev", "narHash": "darwin-hash"}},
    },
}


class AuditOverridesTests(unittest.TestCase):
    def setUp(self):
        cache = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache")
        cache.mkdir(parents=True, exist_ok=True)
        scratch = self.enterContext(tempfile.TemporaryDirectory(dir=cache))
        self.root = Path(scratch)
        self.write("flake.lock", json.dumps(LOCK))
        self.write(
            "overlays/example/default.nix",
            """
# audit-package: example linux
# audit-review: Test the forked behavior.
# Fixed upstream: https://github.com/example/example/pull/42
_: final: prev: {
  example = prev.example.overrideAttrs (old: {
    version = "2.0";
    patches = [ ./local.patch (final.fetchpatch2 {
      url = "https://github.com/example/example/pull/42.patch";
      hash = "sha256-pinned";
    }) ];
  });
}
""",
        )
        self.write("overlays/example/local.patch", "local patch")
        self.write(
            "patches/nixpkgs/default.nix",
            """
_: [
  # url = "https://github.com/example/example/pull/123.patch";
  {
    url = "https://github.com/NixOS/nixpkgs/pull/567.diff";
    revert = true;
  }
]
""",
        )
        self.write("patches/empty/default.nix", "_: [\n  # example\n]\n")
        self.write("patches/dynamic/default.nix", "pkgs: [ (import ./patch.nix pkgs) ]")

    def write(self, filename, contents):
        path = self.root / filename
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(contents)

    def snapshot(self):
        return {
            path.relative_to(self.root): (path.stat().st_ino, path.read_bytes())
            for path in self.root.rglob("*")
            if path.is_file()
        }

    def test_inventory_is_read_only_and_ignores_template_references(self):
        before = self.snapshot()
        with (
            patch.object(auditor, "nix_eval") as evaluate,
            contextlib.redirect_stdout(io.StringIO()) as stdout,
        ):
            self.assertEqual(
                auditor.main(["--root", str(self.root), "--json", "--inventory-only"]),
                0,
            )
        evaluate.assert_not_called()
        self.assertEqual(self.snapshot(), before)
        report = json.loads(stdout.getvalue())
        entries = {entry["path"]: entry for entry in report["entries"]}
        self.assertEqual(
            set(entries), {"overlays/example", "patches/nixpkgs", "patches/dynamic"}
        )
        overlay = entries["overlays/example"]
        self.assertEqual(overlay["local_patches"], ["overlays/example/local.patch"])
        self.assertEqual(
            overlay["references"], ["https://github.com/example/example/pull/42"]
        )
        self.assertEqual(overlay["comparisons"][0]["status"], "manual")
        input_patch = entries["patches/nixpkgs"]
        self.assertEqual(
            input_patch["references"], ["https://github.com/NixOS/nixpkgs/pull/567"]
        )
        self.assertEqual(input_patch["locked_inputs"], {"nixpkgs": "linux-rev"})
        self.assertIn(
            ("revert", "true"),
            [(field["field"], field["value"]) for field in input_patch["declarations"]],
        )

    def test_same_version_does_not_hide_a_different_source(self):
        with patch.object(
            auditor,
            "nix_eval",
            side_effect=[
                "/nix/store/locked-input",
                {"version": "2.0", "sourceHash": "upstream", "sourceRev": None},
                {"version": "2.0", "sourceHash": "fork", "sourceRev": "123"},
            ],
        ) as evaluate:
            report = auditor.audit(self.root, LOCK, "x86_64-linux", False)

        self.assertEqual(report["baseline"]["rev"], "linux-rev")
        baseline, locked, overlay = evaluate.call_args_list
        self.assertEqual(
            json.loads(baseline.kwargs["locked"]), LOCK["nodes"]["linux"]["locked"]
        )
        self.assertEqual(locked.kwargs["source"], "/nix/store/locked-input")
        self.assertEqual(locked.kwargs["overlay"], "")
        self.assertEqual(overlay.kwargs["overlay"], str(self.root / "overlays/example"))
        entry = report["entries"][0]
        self.assertEqual(entry["status"], "manual")
        comparison = entry["comparisons"][0]
        self.assertEqual(comparison["status"], "compared")
        self.assertEqual(comparison["version"], "same")
        self.assertEqual(comparison["sourceHash"], "different")
        self.assertEqual(comparison["sourceRev"], "unknown")

    def test_darwin_uses_unstable_and_skips_linux_targets(self):
        with patch.object(
            auditor, "nix_eval", return_value="/nix/store/input"
        ) as evaluate:
            report = auditor.audit(self.root, LOCK, "aarch64-darwin", False)
        evaluate.assert_called_once()
        self.assertEqual(report["baseline"]["input"], "nixpkgs-unstable")
        comparison = report["entries"][0]["comparisons"][0]
        self.assertEqual(comparison["status"], "manual")
        self.assertIn("applies to linux", comparison["reason"])

    def test_failed_or_missing_packages_are_inconclusive(self):
        with patch.object(
            auditor, "nix_eval", side_effect=[None, ValueError("overlay failed")]
        ):
            comparison = auditor.compare_package(
                self.root, "/nix/store/input", "x86_64-linux", self.root, "missing"
            )
        self.assertEqual(comparison["status"], "inconclusive")
        self.assertIn("locked: package attribute missing", comparison["reason"])
        self.assertIn("overlay: overlay failed", comparison["reason"])

    def test_locked_source_failure_preserves_inventory(self):
        with patch.object(
            auditor, "nix_eval", side_effect=ValueError("input not cached")
        ):
            report = auditor.audit(self.root, LOCK, "x86_64-linux", False)
        self.assertEqual(report["baseline"]["error"], "input not cached")
        self.assertEqual(
            report["entries"][0]["comparisons"][0]["status"], "inconclusive"
        )


if __name__ == "__main__":
    unittest.main()
