import importlib.util
import pathlib
import unittest

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


if __name__ == "__main__":
    unittest.main()
