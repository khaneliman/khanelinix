from __future__ import annotations

import re
import unittest
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parents[1]
LINK_RE = re.compile(r"!?\[[^]]*\]\(([^)]+)\)")


class ArchitectReferenceContract(unittest.TestCase):
    def test_relative_links_stay_inside_plugin_package(self) -> None:
        skill_root = SKILL_ROOT.resolve()
        for document in sorted(SKILL_ROOT.rglob("*.md")):
            content = document.read_text(encoding="utf-8")
            for target in LINK_RE.findall(content):
                if target.startswith(("http://", "https://", "mailto:")):
                    continue
                relative_target = target.split("#", maxsplit=1)[0]
                if not relative_target:
                    continue
                resolved = (document.parent / relative_target).resolve()
                self.assertTrue(
                    resolved.is_relative_to(skill_root),
                    f"{document.relative_to(SKILL_ROOT)} escapes to {target}",
                )
                self.assertTrue(
                    resolved.exists(),
                    f"{document.relative_to(SKILL_ROOT)} links to missing {target}",
                )


if __name__ == "__main__":
    unittest.main()
