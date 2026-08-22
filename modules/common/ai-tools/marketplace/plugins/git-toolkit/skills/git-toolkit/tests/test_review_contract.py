from __future__ import annotations

import hashlib
import unittest
from pathlib import Path

REFERENCE = Path(__file__).resolve().parents[1] / "references" / "adversarial-review.md"
LICENSE = REFERENCE.parents[1] / "LICENSES" / "LICENSE-matt-pocock.txt"


class ReviewContractTests(unittest.TestCase):
    def test_standards_and_spec_feed_one_local_verdict(self) -> None:
        text = REFERENCE.read_text(encoding="utf-8")
        lowered = " ".join(text.lower().split())

        self.assertIn("**Standards:**", text)
        self.assertIn("**Spec:**", text)
        self.assertIn("scope creep", lowered)
        self.assertIn("cite the owning rule", lowered)
        self.assertIn("one verdict", lowered)
        self.assertIn("separate workers are optional", lowered)
        self.assertIn("do not add a generic smell baseline", lowered)
        self.assertEqual(
            hashlib.sha256(LICENSE.read_bytes()).hexdigest(),
            "0e7ac423bf2c6e223b7c5b156f8cf72da49d748e56a1641402c31f22ad07dbb5",
        )


if __name__ == "__main__":
    unittest.main()
