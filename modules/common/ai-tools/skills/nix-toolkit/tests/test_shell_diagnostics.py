from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPTS_DIR = Path(__file__).parents[1] / "scripts"


def create_stub_environment(tmp_dir: Path) -> dict[str, str]:
    stub_nix = tmp_dir / "nix"
    stub_nix.write_text(
        """#!/usr/bin/env bash
if [ -n "${NIX_SHOW_STATS_PATH:-}" ]; then
    cat <<'EOF_STATS' > "$NIX_SHOW_STATS_PATH"
{"nrThunks": 100, "nrAvoided": 25, "nrValues": 500, "nrOpUpdateValuesCopied": 42, "gc": {"totalBytes": 1048576}}
EOF_STATS
fi

subcmd="${1:-}"
shift || true

case "$subcmd" in
    eval)
        raw=false
        json=false
        for arg in "$@"; do
            if [ "$arg" = "--raw" ]; then raw=true; fi
            if [ "$arg" = "--json" ]; then json=true; fi
        done
        if [ "$raw" = true ]; then
            echo "/nix/store/11111111111111111111111111111111-resolved.drv"
        elif [ "$json" = true ]; then
            cat <<'EOF_JSON'
[
  {"name": "hello-2.12.3", "pname": "hello", "version": "2.12.3", "drvPath": "/nix/store/aaa-hello.drv"},
  {"name": "git-2.44.0", "pname": "git", "version": "2.44.0", "drvPath": "/nix/store/bbb-git.drv"}
]
EOF_JSON
        fi
        ;;
    build)
        echo "/nix/store/11111111111111111111111111111111-built-output"
        ;;
    path-info)
        case "${1:-}" in
            -Sh)
                echo "10.0M $2"
                ;;
            -rSh)
                echo "10.0M $2"
                ;;
            -r)
                echo "$2"
                echo "/nix/store/33333333333333333333333333333333-dep-bin"
                ;;
            --recursive)
                echo "10.0M 5.0M 15.0M $6"
                ;;
            *)
                echo "10.0M"
                ;;
        esac
        ;;
    store)
        echo "store diff-closures dummy output"
        ;;
    derivation)
        cat <<'EOF_DRV'
{
  "derivations": {
    "11111111111111111111111111111111-glibc-2.39.drv": {},
    "22222222222222222222222222222222-hello-2.12.3.drv": {}
  }
}
EOF_DRV
        ;;
    why-depends)
        echo "why-depends dummy output"
        ;;
esac
"""
    )
    stub_nix.chmod(0o755)

    stub_nix_store = tmp_dir / "nix-store"
    stub_nix_store.write_text(
        """#!/usr/bin/env bash
echo "/nix/store/33333333333333333333333333333333-dep-bin"
"""
    )
    stub_nix_store.chmod(0o755)

    stub_hyperfine = tmp_dir / "hyperfine"
    stub_hyperfine.write_text(
        """#!/usr/bin/env bash
/bin/sh -c "${@: -1}" || exit "$?"
echo "Benchmark 1: mock command"
echo "  Time (mean ± σ):     100.0 ms ±   2.0 ms"
"""
    )
    stub_hyperfine.chmod(0o755)

    env = os.environ.copy()
    env["PATH"] = f"{tmp_dir}:{env.get('PATH', '')}"
    return env


class ClosureDiffReportTest(unittest.TestCase):
    script = SCRIPTS_DIR / "closure-diff-report.sh"

    def test_missing_arguments_exits_2(self) -> None:
        res = subprocess.run(
            ["bash", str(self.script)], capture_output=True, text=True, check=False
        )
        self.assertEqual(res.returncode, 2)
        self.assertIn("usage: closure-diff-report.sh", res.stderr)

        res_one = subprocess.run(
            ["bash", str(self.script), "/nix/store/aaa"],
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(res_one.returncode, 2)

    def test_store_paths_diff(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            env = create_stub_environment(Path(tmp))
            res = subprocess.run(
                [
                    "bash",
                    str(self.script),
                    "/nix/store/11111111111111111111111111111111-pkg-a",
                    "/nix/store/22222222222222222222222222222222-pkg-b",
                ],
                env=env,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(res.returncode, 0, res.stderr)
            self.assertIn(
                "before input: /nix/store/11111111111111111111111111111111-pkg-a",
                res.stdout,
            )
            self.assertIn(
                "after input: /nix/store/22222222222222222222222222222222-pkg-b",
                res.stdout,
            )
            self.assertIn("== diff-closures ==", res.stdout)
            self.assertIn("== added paths ==", res.stdout)
            self.assertIn("== removed paths ==", res.stdout)
            self.assertIn("== largest after closure entries ==", res.stdout)

    def test_resolves_installables_via_build(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            env = create_stub_environment(Path(tmp))
            res = subprocess.run(
                ["bash", str(self.script), ".#before", ".#after"],
                env=env,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(res.returncode, 0, res.stderr)
            self.assertIn(
                "before output: /nix/store/11111111111111111111111111111111-built-output",
                res.stdout,
            )


class DependencyTraceTest(unittest.TestCase):
    script = SCRIPTS_DIR / "dependency-trace.sh"

    def test_missing_arguments_exits_2(self) -> None:
        res = subprocess.run(
            ["bash", str(self.script)], capture_output=True, text=True, check=False
        )
        self.assertEqual(res.returncode, 2)
        self.assertIn("usage: dependency-trace.sh", res.stderr)

    def test_too_many_arguments_exits_2(self) -> None:
        res = subprocess.run(
            ["bash", str(self.script), "a", "b", "c"],
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(res.returncode, 2)

    def test_target_only_trace(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            env = create_stub_environment(Path(tmp))
            res = subprocess.run(
                [
                    "bash",
                    str(self.script),
                    "/nix/store/11111111111111111111111111111111-pkg",
                ],
                env=env,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(res.returncode, 0, res.stderr)
            self.assertIn(
                "target input: /nix/store/11111111111111111111111111111111-pkg",
                res.stdout,
            )
            self.assertIn("== direct runtime references ==", res.stdout)
            self.assertIn("== recursive closure summary ==", res.stdout)
            self.assertNotIn("== runtime why-depends ==", res.stdout)

    def test_target_and_dependency_trace(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            env = create_stub_environment(Path(tmp))
            res = subprocess.run(
                [
                    "bash",
                    str(self.script),
                    "/nix/store/11111111111111111111111111111111-pkg",
                    "/nix/store/33333333333333333333333333333333-dep-bin",
                ],
                env=env,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(res.returncode, 0, res.stderr)
            self.assertIn("== runtime why-depends ==", res.stdout)
            self.assertIn("== derivation why-depends ==", res.stdout)
            self.assertIn(
                "== closure entries matching dependency output name ==", res.stdout
            )
            self.assertIn(
                "== closure entries matching dependency package name ==", res.stdout
            )


class PackageOptionScanTest(unittest.TestCase):
    script = SCRIPTS_DIR / "package-option-scan.sh"

    def test_missing_arguments_exits_2(self) -> None:
        res = subprocess.run(
            ["bash", str(self.script)], capture_output=True, text=True, check=False
        )
        self.assertEqual(res.returncode, 2)
        self.assertIn("usage: package-option-scan.sh", res.stderr)

    def test_unfiltered_package_scan(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            env = create_stub_environment(Path(tmp))
            res = subprocess.run(
                [
                    "bash",
                    str(self.script),
                    ".#nixosConfigurations.host.config.environment.systemPackages",
                ],
                env=env,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(res.returncode, 0, res.stderr)
            data = json.loads(res.stdout)
            self.assertEqual(len(data), 2)
            self.assertEqual(data[0]["name"], "hello-2.12.3")
            self.assertEqual(data[1]["name"], "git-2.44.0")

    def test_pattern_filtered_scan(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            env = create_stub_environment(Path(tmp))
            res = subprocess.run(
                ["bash", str(self.script), ".#pkgs", "HELLO"],
                env=env,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(res.returncode, 0, res.stderr)
            data = json.loads(res.stdout)
            self.assertEqual(len(data), 1)
            self.assertEqual(data[0]["pname"], "hello")

    def test_pattern_with_no_matches_returns_empty_list(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            env = create_stub_environment(Path(tmp))
            res = subprocess.run(
                ["bash", str(self.script), ".#pkgs", "nonexistent"],
                env=env,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(res.returncode, 0, res.stderr)
            data = json.loads(res.stdout)
            self.assertEqual(data, [])


class DrvGraphGrepTest(unittest.TestCase):
    script = SCRIPTS_DIR / "drv-graph-grep.sh"

    def test_help_flag_exits_0(self) -> None:
        res = subprocess.run(
            ["bash", str(self.script), "--help"],
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(res.returncode, 0)
        self.assertIn("usage: drv-graph-grep.sh", res.stdout)

    def test_missing_arguments_exits_2(self) -> None:
        res = subprocess.run(
            ["bash", str(self.script)], capture_output=True, text=True, check=False
        )
        self.assertEqual(res.returncode, 2)
        self.assertIn("usage: drv-graph-grep.sh", res.stderr)

    def test_search_drv_store_path(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            env = create_stub_environment(Path(tmp))
            res = subprocess.run(
                [
                    "bash",
                    str(self.script),
                    "/nix/store/11111111111111111111111111111111-hello.drv",
                    "glibc",
                ],
                env=env,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(res.returncode, 0, res.stderr)
            self.assertIn(
                "target: /nix/store/11111111111111111111111111111111-hello.drv",
                res.stdout,
            )
            self.assertIn(
                "/nix/store/11111111111111111111111111111111-glibc-2.39.drv", res.stdout
            )

    def test_search_installable_with_allow_meta(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            env = create_stub_environment(Path(tmp))
            res = subprocess.run(
                ["bash", str(self.script), "--allow-meta", "nixpkgs#hello", "hello"],
                env=env,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(res.returncode, 0, res.stderr)
            self.assertIn("target: nixpkgs#hello", res.stdout)
            self.assertIn(
                "drv: /nix/store/11111111111111111111111111111111-resolved.drv",
                res.stdout,
            )
            self.assertIn(
                "/nix/store/22222222222222222222222222222222-hello-2.12.3.drv",
                res.stdout,
            )


class EvalBenchmarkTest(unittest.TestCase):
    script = SCRIPTS_DIR / "eval-benchmark.sh"

    def test_help_flag_exits_0(self) -> None:
        res = subprocess.run(
            ["bash", str(self.script), "--help"],
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(res.returncode, 0)
        self.assertIn("usage: eval-benchmark.sh", res.stdout)

    def test_missing_arguments_exits_2(self) -> None:
        res = subprocess.run(
            ["bash", str(self.script)], capture_output=True, text=True, check=False
        )
        self.assertEqual(res.returncode, 2)
        self.assertIn("usage: eval-benchmark.sh", res.stderr)

    def test_missing_option_values_exit_2(self) -> None:
        for option in ("--runs", "--warmup"):
            for remainder in ([], [""], ["--warmup", "2", "nix", "eval"]):
                with self.subTest(option=option, remainder=remainder):
                    res = subprocess.run(
                        ["bash", str(self.script), option, *remainder],
                        capture_output=True,
                        text=True,
                        check=False,
                    )
                    self.assertEqual(res.returncode, 2)
                    self.assertIn("usage: eval-benchmark.sh", res.stderr)

    def test_benchmark_and_stats_preserve_argv(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_dir = Path(tmp)
            env = create_stub_environment(tmp_dir)
            capture = tmp_dir / "capture argv's.py"
            capture.write_text(
                "import json, os, sys\n"
                "with open(os.environ['ARGV_LOG'], 'a') as log:\n"
                "    log.write(json.dumps(sys.argv[1:]) + '\\n')\n"
                "if 'NIX_SHOW_STATS_PATH' in os.environ:\n"
                "    with open(os.environ['NIX_SHOW_STATS_PATH'], 'w') as stats:\n"
                "        stats.write('{}')\n"
            )
            log = tmp_dir / "argv.jsonl"
            env["ARGV_LOG"] = str(log)
            args = [
                "",
                "two words",
                "it's quoted",
                "$HOME $(exit 42)",
                "`exit 43`",
                "line one\nline two\n",
                "a; exit 44",
                "*",
                "back\\slash",
            ]
            res = subprocess.run(
                ["bash", str(self.script), "--", sys.executable, str(capture), *args],
                env=env,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(res.returncode, 0, res.stderr)
            invocations = [json.loads(line) for line in log.read_text().splitlines()]
            expected = args + ["--option", "eval-cache", "false"]
            self.assertEqual(invocations, [expected, expected])

    def test_benchmark_execution_and_stats(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            env = create_stub_environment(Path(tmp))
            res = subprocess.run(
                [
                    "bash",
                    str(self.script),
                    "--runs",
                    "5",
                    "--warmup",
                    "2",
                    "nix",
                    "eval",
                    ".#drv",
                ],
                env=env,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(res.returncode, 0, res.stderr)
            self.assertIn(
                "benchmark command: nix eval .#drv --option eval-cache false",
                res.stdout,
            )
            self.assertIn("Benchmark 1: mock command", res.stdout)
            self.assertIn("== evaluator stats, single run ==", res.stdout)
            self.assertIn('"nrThunks": 100', res.stdout)
            self.assertIn('"sets": 42', res.stdout)
            self.assertIn('"gcTotalBytes": 1048576', res.stdout)


if __name__ == "__main__":
    unittest.main()
