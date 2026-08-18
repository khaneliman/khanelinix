# Portable AI-tool marketplace

This repository publishes portable skills directly from their canonical
directories. Consumers do not need Nix, Python, or a repository clone.

## Install one skill for all providers

Use the open Agent Skills installer for Antigravity, Claude Code, and Codex:

```sh
npx skills add khaneliman/khanelinix \
  --agent antigravity claude-code codex \
  --skill git-toolkit \
  --global \
  --copy \
  --yes
```

Replace `git-toolkit` with a published skill name from `catalog.json`. Select
skills explicitly. The repository also contains internal or host-bound skills
that the marketplace excludes.

## Use the Codex marketplace

Current Codex releases require separate marketplace and plugin commands:

```sh
codex plugin marketplace add https://github.com/khaneliman/khanelinix
codex plugin add git-toolkit@khanelinix-ai-tools
```

`codex plugin add https://github.com/khaneliman/khanelinix` is not supported.
The `plugin add` command accepts a plugin name and marketplace name.

## Use the Claude marketplace

```sh
claude plugin marketplace add https://github.com/khaneliman/khanelinix
claude plugin install git-toolkit@khanelinix-ai-tools
```

## Maintain the marketplace

The repository root contains both provider indexes:

- `.agents/plugins/marketplace.json` for Codex
- `.claude-plugin/marketplace.json` for Claude Code

Each published skill directory contains its Codex plugin manifest. Claude Code
uses the skill directory's root `SKILL.md` directly.

`catalog.json` must publish or exclude every canonical skill. Add an exclusion
reason when license or runtime constraints prevent portable distribution.
Increase a plugin version when its canonical skill content changes.

Run the read-only validator after a metadata or skill change:

```sh
python3 modules/common/ai-tools/marketplace/marketplace.py --root .
```

The Python command is a maintainer check. It does not generate consumer files.
