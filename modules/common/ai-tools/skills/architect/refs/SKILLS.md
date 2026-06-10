# Standards for Stateless Skills

Skills are reusable, multi-step workflows package-managed as directories
containing a `SKILL.md` playbook, optionally supported by scripts, assets, and
references.

## Design Constraints

1. **Lean Playbook:** Keep the root `SKILL.md` under 100 lines. Focus on
   triggers, high-level workflow steps, and execution routing.
2. **On-Demand Loading:** Place detailed manuals, syntax examples, checklists,
   and edge-cases in a `references/` or `refs/` directory. Instruct the AI to
   read them only when relevant.
3. **Executable Automation:** Move repetitive mechanical operations, linting
   checks, or scaffolding tasks into `scripts/` instead of describing the manual
   steps in markdown.
4. **Precise Triggers:** Use specific frontmatter descriptions to prevent
   false-positive activation during generic tasks.
5. **No State:** Do not store task-specific state in the skill. Keep the logic
   purely functional.

---

## Claude-Specific Context Behaviors

- **Compaction Re-injection & Limits:** Invoked skill bodies are automatically
  re-injected after conversation compaction. However, they are capped at **5,000
  tokens per skill** and **25,000 tokens total** for all skills. Oldest skills
  are dropped once the total budget is exceeded.
- **Truncation:** Since truncation keeps the start of the file, always put the
  most important instructions near the top of `SKILL.md` and move detailed
  payload to reference files. Progressive disclosure prevents truncation of
  critical data.

---

## Codex Agent Skills

Codex supports the open agent skills standard (agentskills.io).

### Structure & Layout

- A skill folder contains:
  - `SKILL.md` **(Required)**: Playbook instructions and frontmatter metadata
    (`name`, `description`).
  - `scripts/` **(Optional)**: Executable automation.
  - `references/` **(Optional)**: Detailed documentation.
  - `assets/` **(Optional)**: Templates/resources.
  - `agents/openai.yaml` **(Optional)**: UI display options, invocation policy,
    and MCP tool dependencies.

### Discovery & Scoping Locations

- **`REPO`:** Scanned under `$CWD/.agents/skills` up to
  `$REPO_ROOT/.agents/skills`. Symlinks are followed.
- **`USER`:** Personal skills under `$HOME/.agents/skills`.
- **`ADMIN`:** Shared system-wide skills under `/etc/codex/skills`.
- **`SYSTEM`:** Bundled directly with Codex.

### Implicit Match Budget

- The initial list of all available skills in context is capped at **2% of the
  context window** (approx. 8,000 characters when unknown).
- If budget is exceeded, Codex shortens descriptions first, then omits skills.
- **Design Rule:** Front-load key use cases and trigger words in the description
  frontmatter so matching works even when truncated.
- Disable specific skills in `~/.codex/config.toml` using:
  ```toml
  [[skills.config]]
  path = "/path/to/skill/SKILL.md"
  enabled = false
  ```

**Actionable Advice Output:** Propose the directory structure, draft the
`SKILL.md` frontmatter, draft any `agents/openai.yaml` dependencies, and suggest
trigger words to keep under the 8,000-character match budget.
