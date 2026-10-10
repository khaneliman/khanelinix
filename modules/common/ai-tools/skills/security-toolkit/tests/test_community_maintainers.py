from __future__ import annotations

import importlib.util
import math
import unittest
from pathlib import Path

SCRIPT = Path(__file__).parents[1] / "scripts" / "community_maintainers.py"
SPEC = importlib.util.spec_from_file_location("community_maintainers", SCRIPT)
maintainers = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(maintainers)


class RecencyTests(unittest.TestCase):
    def test_advertised_half_life(self):
        for age, half, expected in (
            (0, 180, 1),
            (180, 180, 0.5),
            (360, 180, 0.25),
            (30, 30, 0.5),
            (10, 0, 1),
            (10, -1, 1),
        ):
            with self.subTest(age=age, half=half):
                self.assertTrue(
                    math.isclose(maintainers.recency_weight(age, half), expected)
                )


if __name__ == "__main__":
    unittest.main()
