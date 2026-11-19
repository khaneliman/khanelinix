import contextlib
import importlib.util
import io
import pathlib
import sys
import unittest
from unittest.mock import patch

SCRIPT_PATH = pathlib.Path(__file__).with_name("why-depends.py")
spec = importlib.util.spec_from_file_location("why_depends_script", SCRIPT_PATH)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

parse_derivation_show_output = module.parse_derivation_show_output
DerivationShowParseError = module.DerivationShowParseError


class ParseDerivationShowOutputTests(unittest.TestCase):
    def test_legacy_output(self):
        payload = """
        {
          "/nix/store/legacy-1": {
            "name": "legacy",
            "inputDrvs": {}
          }
        }
        """
        data = parse_derivation_show_output(payload)
        self.assertIn("/nix/store/legacy-1", data)
        self.assertEqual(data["/nix/store/legacy-1"]["name"], "legacy")

    def test_wrapped_output(self):
        payload = """
        {
          "version": 4,
          "derivations": {
            "/nix/store/wrapped-1": {
              "name": "wrapped",
              "inputDrvs": {}
            }
          }
        }
        """
        data = parse_derivation_show_output(payload)
        self.assertIn("/nix/store/wrapped-1", data)
        self.assertEqual(data["/nix/store/wrapped-1"]["name"], "wrapped")

    def test_bad_top_level_shape(self):
        payload = """
        {
          "version": 4,
          "derivations": []
        }
        """
        with self.assertRaises(DerivationShowParseError):
            parse_derivation_show_output(payload)


class HostDiagnosticTests(unittest.TestCase):
    def test_list_configurations_hint_is_correct_and_printed_once(self):
        for fast in (False, True):
            for reason in ("not_in_darwin", "unknown_error"):
                with self.subTest(fast=fast, reason=reason):
                    argv = ["why-depends", "missing", "firefox"]
                    if fast:
                        argv.append("--fast")
                    output = io.StringIO()
                    with (
                        patch.object(sys, "argv", argv),
                        patch.object(
                            module,
                            "check_config_exists_fast",
                            side_effect=[(False, "not_in_nixos"), (False, reason)],
                        ),
                        patch.object(
                            module,
                            "nix_build_safe",
                            side_effect=[
                                (False, "not_in_nixos", None),
                                (False, reason, None),
                            ],
                        ),
                        contextlib.redirect_stdout(output),
                        self.assertRaises(SystemExit) as error,
                    ):
                        module.main()
                    self.assertEqual(error.exception.code, 1)
                    self.assertEqual(output.getvalue().count("nix flake show"), 1)
                    self.assertNotIn("nix flake build", output.getvalue())


if __name__ == "__main__":
    unittest.main()
