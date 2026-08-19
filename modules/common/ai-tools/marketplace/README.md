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

`catalog.json` is the single source for names, display names, descriptions,
versions, categories, bundles, and exclusions. `sync.py` generates the consumer
files from it:

- `.agents/plugins/marketplace.json`, the Codex index
- `.claude-plugin/marketplace.json`, the Claude Code index
- `marketplace/plugins/<name>/`, one plugin per published skill with a Codex and
  a Claude manifest over one copy of the canonical skill under `skills/<name>/`

Both providers load plugin skills only from `skills/<name>/SKILL.md` under the
plugin root. A root `SKILL.md` installs, and Claude Code CLI sessions even
expose it, but Codex sessions expose nothing and Claude Desktop counts zero
skills, so the nested layout is the contract.

After any change to `catalog.json` or a published skill, run:

```sh
python3 modules/common/ai-tools/marketplace/sync.py
```

`catalog.json` must publish or exclude every canonical skill. Add an exclusion
reason when license or runtime constraints prevent portable distribution.

Run the read-only validator after a metadata or skill change:

```sh
python3 modules/common/ai-tools/marketplace/marketplace.py --root .
```

The Python command is a maintainer check. It does not generate consumer files.
