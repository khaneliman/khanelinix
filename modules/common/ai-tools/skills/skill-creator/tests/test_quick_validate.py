from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "quick_validate", Path(__file__).parents[1] / "scripts" / "quick_validate.py"
)
quick_validate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(quick_validate)


class QuickValidateTest(unittest.TestCase):
    def validate(self, extra):
        with tempfile.TemporaryDirectory() as directory:
            (Path(directory) / "SKILL.md").write_text(
                "---\nname: example\ndescription: Example skill\n"
                + extra
                + "---\n# Example\n"
            )
            return quick_validate.validate_skill(directory)

    def test_native_invocation_boolean(self):
        for value in ("true", "false"):
            with self.subTest(value=value):
                self.assertTrue(
                    self.validate(f"disable-model-invocation: {value}\n")[0]
                )

    def test_native_invocation_requires_boolean(self):
        for value in ('"true"', "1", "null", "[]", "{}"):
            with self.subTest(value=value):
                valid, message = self.validate(f"disable-model-invocation: {value}\n")
                self.assertFalse(valid)
                self.assertIn("must be a boolean", message)

    def test_existing_schema_stays_strict(self):
        self.assertTrue(self.validate("")[0])
        self.assertFalse(self.validate("unknown-field: true\n")[0])

    def test_canonical_explicit_only_skills(self):
        skills = Path(__file__).parents[2]
        for name in ("program-orchestration", "to-spec", "to-tickets"):
            with self.subTest(name=name):
                valid, message = quick_validate.validate_skill(skills / name)
                self.assertTrue(valid, message)


if __name__ == "__main__":
    unittest.main()
