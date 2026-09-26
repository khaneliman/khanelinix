import importlib.util
import os
import tempfile
import unittest
from pathlib import Path

import tomlkit

SPEC = importlib.util.spec_from_file_location(
    "sync_config", Path(__file__).parents[1] / "sync-config.py"
)
SYNC = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(SYNC)


class ConfigSyncTests(unittest.TestCase):
    def setUp(self):
        cache = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
        cache.mkdir(parents=True, exist_ok=True)
        self.directory = tempfile.TemporaryDirectory(dir=cache)
        self.addCleanup(self.directory.cleanup)
        root = Path(self.directory.name)
        self.source = root / "declared.toml"
        self.target = root / "config.toml"
        self.snapshot = root / "state" / "previous.toml"
        self.source.write_text('model = "default"\n[features]\nold = true\n')

    def sync(self):
        SYNC.sync_config(self.source, self.target, self.snapshot)
        return tomlkit.parse(self.target.read_text())

    def test_replaces_store_symlink_without_modifying_source(self):
        self.source.chmod(0o444)
        self.target.symlink_to(self.source)
        original = self.source.read_text()
        self.sync()
        self.assertFalse(self.target.is_symlink())
        self.assertEqual(self.target.stat().st_mode & 0o777, 0o600)
        self.assertEqual(self.source.read_text(), original)

    def test_retains_selection_and_trust_while_updating_declared_settings(self):
        self.sync()
        self.target.write_text(
            'model = "selected"\n[features]\nold = true\n'
            '[projects."/work"]\ntrust_level = "trusted"\n'
        )
        self.source.write_text('model = "default"\n[features]\nnew = true\n')
        result = self.sync()
        self.assertEqual(result["model"], "selected")
        self.assertEqual(result["features"], {"new": True})
        self.assertEqual(result["projects"]["/work"]["trust_level"], "trusted")
        self.assertEqual(self.sync(), result)

    def test_explicit_declarative_default_change_wins(self):
        self.sync()
        self.target.write_text('model = "selected"\n')
        self.source.write_text('model = "new-default"\n')
        self.assertEqual(self.sync()["model"], "new-default")

    def test_invalid_user_config_is_not_overwritten(self):
        self.sync()
        self.target.write_text("not valid TOML")
        previous = self.snapshot.read_text()
        with self.assertRaises(tomlkit.exceptions.ParseError):
            self.sync()
        self.assertEqual(self.target.read_text(), "not valid TOML")
        self.assertEqual(self.snapshot.read_text(), previous)


if __name__ == "__main__":
    unittest.main()
