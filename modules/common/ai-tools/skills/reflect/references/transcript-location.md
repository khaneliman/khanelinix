# Locate the Active Transcript

Transcript stores vary per provider. Claude Code writes one JSONL file per
session under its config directory in `projects/<workspace-slug>/`.

List candidates from the current workspace transcript directory only:

```bash
ls -t <transcript-dir>/*.jsonl <transcript-dir>/*/*.jsonl \
  <transcript-dir>/*/subagents/*.jsonl 2>/dev/null | head -10
```

Do not glob across other workspace slugs. Cross-slug globs read private sessions
from unrelated projects.

Providers use up to three layouts: flat (`<id>.jsonl`), nested
(`<id>/<id>.jsonl`), and subagent (`<parent>/subagents/<child>.jsonl`).

Read the first JSONL line of each candidate. Confirm the first message text
holds this conversation's opening user prompt. Take the matching path.
