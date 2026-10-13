# Standards for Subagents and Custom Agents

Use subagents to isolate context, run independent work in parallel, or give a
narrow role its own tools.

## Design Constraints

1. **Self-contained packet.** A subagent sees no conversation history. Give the
   task, inputs, verified context, constraints, and exit criteria in its prompt.
2. **One narrow role.** Define a single-responsibility role, such as "Nix build
   debugger", not a general helper.
3. **Clear exit criteria.** State exactly what to return and when to stop. Ask
   for a condensed result; a summary of one or two thousand tokens keeps the
   parent's context clean.
4. **Least privilege.** Grant only the tools the role needs: read-only tools for
   research and review, write tools only for changes. Omit the delegation tool
   from read-only reviewers so they cannot spawn further agents.
5. **Few checkpoints.** Exchange messages only at major checkpoints, not in a
   chatty loop.
6. **Short descriptions.** Descriptions load on every turn; keep detail in the
   agent body, which loads only when the agent runs.

## Claude Code

- Agents are markdown files in `.claude/agents/` (project) or
  `~/.claude/agents/` (user). `name` (up to 256 characters, no `:`) and
  `description` are required; optional fields include `tools`, `model`, and
  `skills`. Agent fields are camelCase.
- The body is the agent's entire system prompt, replacing the Claude Code system
  prompt. Agents still receive `CLAUDE.md` unless `omitClaudeMd` is set.
- Omitting `tools` grants every tool. `model` accepts `sonnet`, `opus`, `haiku`,
  a full model ID, or `inherit`.
- `skills` preloads full skill content; skills with
  `disable-model-invocation: true` cannot be preloaded.
- Agents can nest; remove the `Agent` tool from roles that must not delegate.
- Delegate large reads and research to a subagent so the main session avoids
  compaction; only the result returns to the parent.

## Codex

- Custom agents are TOML files in `~/.codex/agents/` or `.codex/agents/`.
  Required: `name`, `description`, `developer_instructions`. Optional:
  `nickname_candidates`, `model`, `model_reasoning_effort`, `sandbox_mode`,
  `mcp_servers`, and `skills.config`. Keep each agent narrow and opinionated.
- `config.toml` sets `agents.max_threads` (concurrent threads),
  `agents.max_depth` (nesting, default 1), and `agents.job_max_runtime_seconds`
  (batch timeout).
- `spawn_agents_on_csv` runs one worker per CSV row; each worker reports with
  `report_agent_job_result`.

## GitHub Copilot

- Custom agents are markdown files in `.github/agents/` (repository,
  organization, or enterprise) and `~/.copilot/agents/` for the CLI.
  `description` is required; `name`, `tools`, `model`,
  `disable-model-invocation`, `user-invocable`, `mcp-servers`, and `metadata`
  are optional. The prompt is limited to 30,000 characters.
- Unknown tool names are ignored, so one profile can list tools for several
  hosts. Claude names map to Copilot aliases, such as `Bash` to execute and
  `Read` to read.

## Output

Provide the exact agent file for each target host and explain how its tool
limits and exit criteria keep context small and prevent recursive delegation.
