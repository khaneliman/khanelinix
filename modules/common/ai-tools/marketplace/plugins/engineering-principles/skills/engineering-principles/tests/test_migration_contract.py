from __future__ import annotations

import hashlib
import unittest
from pathlib import Path

REFERENCE = (
    Path(__file__).resolve().parents[1]
    / "references"
    / "migrate-callers-then-delete-legacy-apis.md"
)
LICENSE = REFERENCE.parents[1] / "LICENSES" / "LICENSE-matt-pocock.txt"


class MigrationContractTests(unittest.TestCase):
    def test_wide_refactor_preserves_eventual_single_path(self) -> None:
        text = REFERENCE.read_text(encoding="utf-8").lower()

        self.assertIn("expand-migrate-contract", text)
        self.assertIn("bounded green batches", text)
        self.assertIn("mechanically recount remaining legacy callers", text)
        self.assertIn("delete the adapter and old path", text)
        self.assertIn("named removal condition", text)
        self.assertEqual(
            hashlib.sha256(LICENSE.read_bytes()).hexdigest(),
            "0e7ac423bf2c6e223b7c5b156f8cf72da49d748e56a1641402c31f22ad07dbb5",
        )


if __name__ == "__main__":
    unittest.main()
