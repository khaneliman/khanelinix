import subprocess
import unittest
from pathlib import Path
from unittest.mock import patch

import update_vicinae_extensions as updater


class UpdateVicinaeExtensionsTests(unittest.TestCase):
    def test_repo_root_keeps_trailing_space(self):
        result = subprocess.CompletedProcess([], 0, "/checkout with space \n", "")
        with patch.object(updater, "run", return_value=result):
            self.assertEqual(updater.get_repo_root(), Path("/checkout with space "))

    def test_hash_probes_use_same_input_and_quote_checkout(self):
        checkout = Path('/checkout with space/${literal}"#')
        rev = "a" * 40
        source_hash = "sha256-AAAA="
        npm_deps_hash = "sha256-BBBB="
        results = [
            subprocess.CompletedProcess([], 1, "", f"got: {hash_value}")
            for hash_value in (source_hash, npm_deps_hash)
        ]
        with patch.object(updater, "run", side_effect=results) as run:
            self.assertEqual(
                updater.get_sparse_hash(checkout, "demo", rev), source_hash
            )
            self.assertEqual(
                updater.get_npm_deps_hash(checkout, "demo", rev, source_hash),
                npm_deps_hash,
            )

        sparse_expr, npm_expr = [call.args[0][-1] for call in run.call_args_list]
        for expr in (sparse_expr, npm_expr):
            self.assertIn(
                'builtins.getFlake "git+file:///checkout%20with%20space/%24%7Bliteral%7D%22%23"',
                expr,
            )
            self.assertIn("import flake.inputs.nixpkgs {", expr)
        self.assertIn(f'hash = "{source_hash}";', npm_expr)
