# Standards for Plugins and Marketplaces

Skills are the authoring format; plugins are how they are installed and
distributed. A plugin bundles skills and optionally agents, hooks, MCP servers,
and commands.

## Design Constraints

1. **One canonical source.** Point each plugin at the canonical skill directory
   instead of copying skill content into a plugin tree.
2. **Portable layout first.** Agent Plugins 1.0 uses a root `plugin.json`,
   `skills/`, and `mcp.json`. Put host-specific settings in namespaced locations
   that other hosts ignore: `.claude-plugin/`, `.codex-plugin/` or
   `extensions.com.openai`, and `com.github.copilot/`.
3. **Every enabled plugin costs context.** Its skill and agent descriptions load
   on every turn, and its hooks fire in every session. Bundle only what belongs
   together, and narrow hook matchers.
4. **Instructions live in skills.** A `CLAUDE.md` at the plugin root is not
   loaded; put guidance in a skill.
5. **Pin deliberately.** A `version` keeps users on that release until it
   changes, so raise it whenever published content or packaging changes.

## Claude Code

- `.claude-plugin/plugin.json` is optional; when present, `name` is the only
  required key. Use kebab-case and avoid names starting with `claude-`,
  `anthropic-`, `anthropics-`, or `cc-plugin-`.
- Keep every component at the plugin root, not inside `.claude-plugin/`.
- Plugin subagents ignore `hooks`, `mcpServers`, `permissionMode`, and
  `initialPrompt`.
- `.claude-plugin/marketplace.json` requires `name`, `owner`, and `plugins`;
  each entry needs `name` and `source`. A typo loads silently.
- Run `claude plugin validate --strict` in CI so warnings fail the build.

## Codex and OpenAI

- New packages use the Agent Plugins `plugin.json` with OpenAI settings under
  `extensions.com.openai`. Codex still accepts legacy `.codex-plugin/` and
  Claude-compatible manifests.
- Marketplaces live at `.agents/plugins/marketplace.json` or the legacy
  `.claude-plugin/marketplace.json`.
- When converting a Claude plugin, turn each command into a skill and move
  reusable agent procedures into skills.

## GitHub Copilot

- Copilot CLI and the Copilot app read `.claude-plugin/marketplace.json` and
  Claude-format plugin roots. Copilot-only files go in `com.github.copilot/`.
- Business and Enterprise policies can restrict installs to approved
  marketplaces.

## Publishing Checklist

1. Each plugin source resolves to its canonical skill directory.
2. Marketplace entries, plugin manifests, and any catalog agree on name,
   description, and version.
3. Host-only skills are excluded from publication.
4. The structural audit passes and its portability warnings are resolved for
   published skills.
5. Host validators pass where available: `claude plugin validate --strict`,
   `skills-ref validate`, and `gh skill publish --dry-run`.
