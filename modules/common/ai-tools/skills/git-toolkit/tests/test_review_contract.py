from __future__ import annotations

import hashlib
import unittest
from pathlib import Path

REFERENCE = Path(__file__).resolve().parents[1] / "references" / "adversarial-review.md"
LICENSE = REFERENCE.parents[1] / "LICENSES" / "LICENSE-matt-pocock.txt"


class ReviewContractTests(unittest.TestCase):
    def test_git_review_defers_to_the_shared_contract(self) -> None:
        lowered = " ".join(REFERENCE.read_text(encoding="utf-8").lower().split())

        self.assertIn("`premise-review` method in `engineering-principles`", lowered)
        self.assertIn("standards and spec evidence axes", lowered)
        self.assertIn("blind brief", lowered)
        self.assertIn("read-only command", lowered)
        self.assertIn("do not invent requirements", lowered)
        self.assertEqual(
            hashlib.sha256(LICENSE.read_bytes()).hexdigest(),
            "0e7ac423bf2c6e223b7c5b156f8cf72da49d748e56a1641402c31f22ad07dbb5",
        )


if __name__ == "__main__":
    unittest.main()
