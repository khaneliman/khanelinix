---
type: convention
title: The okf-memory bundle
tags:
  - ai-tools
  - okf-memory
---

# The okf-memory bundle

This `.okf/` directory is the project-level knowledge bundle, conformant to
[OKF v0.1](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md),
maintained by the `okf-memory` skill defined at
[modules/common/ai-tools/skills/okf-memory/](../../modules/common/ai-tools/skills/okf-memory/SKILL.md).

It holds durable facts and decisions about this specific repo that aren't
already covered by `CONTRIBUTING.md` or `AGENTS.md` — those remain the canonical
source for style, taxonomy, and workflow. This bundle is for things an agent
learns while working here that are worth remembering across sessions and across
providers (Claude Code, Codex, and anything else working in this repo), but
don't belong in human-maintained canon docs.

`MEMORY.local.md`, when it exists, holds bounded curated working memory and is
intentionally not committed (see `.gitignore`). Cross-project user preferences
and reusable lessons live in `${XDG_DATA_HOME:-$HOME/.local/share}/okf`.

Planning-with-files owns transient task/session state. OKF owns durable user or
project knowledge. Provider-native memory may mirror a durable write, but never
substitutes for OKF.

Claude Code, Codex, and Antigravity lifecycle hooks inject bounded user/project
indexes at session start and a short routing nudge at each user turn. A one-shot
Stop checkpoint inspects the completed turn after explicit memory intent or
substantial tool work. It accepts a durable-memory write only when the bundle
changed and the transcript records an OKF-targeting mutation. Hooks fail open
and never copy transcripts or synthesize memory content; the working agent still
decides what verified knowledge deserves persistence.
