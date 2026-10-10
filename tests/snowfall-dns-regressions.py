"""Run: python3 tests/snowfall-dns-regressions.py /locked/nixpkgs.

Evaluate real template DNS children against native NixOS options and merges.
This does not evaluate or complete the unrelated Snowfall scaffold.
"""

import json
import subprocess
import sys
from pathlib import Path

result = json.loads(
    subprocess.check_output(
        [
            "nix-instantiate",
            "--eval",
            "--strict",
            "--json",
            str(Path(__file__).with_suffix(".nix")),
            "--arg",
            "nixpkgs",
            str(Path(sys.argv[1]).resolve()),
        ],
        text=True,
    )
)
assert result["pass"], result["failures"]
print("PASS: seven DNS enable/default/merge checks, including eight disabled cases")
