---
type: convention
title: The okf-memory bundle
tags:
  - ai-tools
  - okf-memory
---

# The okf-memory bundle

This `.okf/` directory is a per-project knowledge bundle, conformant to
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
intentionally not committed (see `.gitignore`).
