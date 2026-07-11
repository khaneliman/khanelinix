# Git Toolkit Scripts

Use scripts for deterministic evidence collection. Keep commit boundaries,
causal analysis, and rewrite decisions in the relevant playbook.

## Available Scripts

- `<path-to-skill>/scripts/stack_report.py --base <ref> [--head <ref>]`:
  read-only status, ahead/behind, commit-message, and touched-path report. JSON
  is default; `--format text` is available. Output lists and keys have stable
  ordering.
- `<path-to-skill>/scripts/bisect_run.py --good <ref> --bad <ref> -- <test
  argv...>`:
  require a clean repository and ancestor-ordered endpoints, run automated
  bisect in a disposable linked worktree, then reset and remove that worktree in
  cleanup. Main HEAD and status are verified unchanged before success is
  reported.

Both scripts accept `--repo <path>` and bound potentially large evidence by
default. `stack_report.py` independently bounds commits, worktree entries, paths
per commit, and commit bodies. `bisect_run.py` bounds tested revisions and the
first-bad commit body, and streams noisy bisect output into fixed-size tail
captures. Reports include total, omitted, and truncation metadata. Evidence-list
and body limits accept `0` for an explicit unlimited report; bisect output
capture always requires a positive safety bound. Run `--help` for exact flags.
