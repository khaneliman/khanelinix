# Nix Toolkit Scripts

Use scripts for first-pass reports and repeatable measurements; use mode
playbooks when diagnosis or custom command shaping is needed.

`<path-to-skill>` is the directory holding this skill's `SKILL.md`. The skill is
installed outside the repository under analysis and runs with the repository as
the working directory, so a bare `scripts/...` path does not resolve. Every
reference uses the prefixed form.

This is an index. Run `--help` for the flag surface, and read the owning
reference for when to reach for the script and how to read its output.

## Available Scripts

| Script                   | Answers                                                     | Owner                                           |
| ------------------------ | ----------------------------------------------------------- | ----------------------------------------------- |
| `option-forensics.sh`    | Why does this option resolve to that value?                 | [Option forensics](option-forensics.md)         |
| `option-tree.sh`         | What is defined across this option subtree?                 | [Option forensics](option-forensics.md)         |
| `module_graph.py`        | Did this module reach the evaluation, and what imported it? | [Option forensics](option-forensics.md)         |
| `trace_eval.py`          | What does this failing evaluation actually say?             | [Option forensics](option-forensics.md)         |
| `config-assertions.sh`   | Which assertions and warnings fire, without building?       | [Module testing](module-testing.md)             |
| `eval-benchmark.sh`      | What does this evaluation cost, across repeated runs?       | [Evaluation performance](eval-performance.md)   |
| `package_diff_report.py` | How do two built installables differ?                       | [Package diffing](package-diffing.md)           |
| `closure-diff-report.sh` | How did the closure drift between two installables?         | [Closure analysis](closure-analysis.md)         |
| `dependency-trace.sh`    | Why does this target depend on that package?                | [Dependency forensics](dependency-forensics.md) |
| `package-option-scan.sh` | Which package-list option pulls this in?                    | [Dependency forensics](dependency-forensics.md) |
| `drv-graph-grep.sh`      | Which derivation in the graph matches, without realizing?   | [Dependency forensics](dependency-forensics.md) |
| `flake_input_report.py`  | How stale are the locked inputs, and what pins them?        | [Flake maintenance](flake-maintenance.md)       |
| `validate-snippets.sh`   | Do this skill's own snippets and cited APIs still hold?     | [Operating rules](operating-rules.md)           |

All query scripts are read-only. `option-forensics.sh`, `option-tree.sh`,
`module_graph.py`, `config-assertions.sh`, and `package-option-scan.sh` realize
nothing. `package_diff_report.py` and `closure-diff-report.sh` build, but never
create result links or touch the lock file.

Three scripts use a non-zero exit as an answer rather than an error:
`config-assertions.sh` exits 1 when an assertion failed, `module_graph.py` exits
1 when nothing matched, and `trace_eval.py` exits 1 when the command failed and
a report was produced.
