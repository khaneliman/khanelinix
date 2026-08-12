# Standards for Subagents

Use subagents to isolate state, run parallel operations, or prevent context
pollution.

## Design Constraints

1. **Context Isolation:** Do not copy the entire global conversation history
   into a subagent's prompt. Provide only the immediate task, input variables,
   and exit criteria.
2. **Narrow Scope/Role:** Define a specific, single-responsibility role (e.g.,
   "Nix Build Debugger", "Rust Clippy Auditor") instead of a general helper.
3. **Clear Exit Criteria:** State exactly what the subagent must output and when
   it should stop (e.g., "Return only the diff of the fix, then exit").
4. **Tool Gating:** Equip the subagent only with the tools necessary for its job
   (e.g., read-only tools for research, write tools only if modifying files is
   required).
5. **No Chatty Loops:** Exchange parent/child messages only at major
   checkpoints. Avoid interactive chatting between parent and child agents
   unless resolving a specific block.

---

## Claude-Specific Context Behaviors

- **Definition Format:** Subagents are markdown files in `.claude/agents/`
  (project) or `~/.claude/agents/` (user) with YAML frontmatter: `name`,
  `description`, and optional `tools` and `model`. The main session spawns them
  through the `Agent` tool; the `description` frontmatter determines when Claude
  delegates automatically.
- **Context Pollution Shield:** Reading large files in the main session quickly
  fills the context window and triggers automatic compaction. Delegate large
  file reads or research tasks to a subagent.
- **Compaction Avoidance:** The subagent performs the heavy read operations in
  its own separate context window. Once complete, only the summary and a small
  metadata trailer are returned to the parent agent, keeping the main session's
  context footprint clean.

---

## Codex Subagents & Instructions (AGENTS.md)

Codex reads `AGENTS.md` instruction chains and spawns subagents to parallelize
complex tasks.

### Instruction Chain Discovery (AGENTS.md)

- **Precedence:**
  1. Global scope: `~/.codex/AGENTS.override.md` -> `~/.codex/AGENTS.md` (only
     first non-empty loads).
  2. Project scope: walks down from project root to current working directory
     checking for `AGENTS.override.md` -> `AGENTS.md` -> fallback names
     configured via `project_doc_fallback_filenames` (e.g. `TEAM_GUIDE.md`). At
     most one file loads per directory.
- **Merge Order:** Concatenated from root down. Files closer to CWD override
  earlier files.
- **Size Limit:** Combined text capped at 32 KiB (`project_doc_max_bytes`). Once
  the cap is reached, Codex stops adding further files; raise the cap or
  redistribute instructions across nested directories to preserve critical
  content.

### Codex Custom Agent Configuration

- **Location:** Defined in standalone TOML files under `~/.codex/agents/`
  (global) or `.codex/agents/` (project-scoped).
- **Required TOML Fields:** `name`, `description`, `developer_instructions`.
- **Optional Fields:** `nickname_candidates` (pool of presentation nicknames to
  distinguish multiple worker runs), `model`, `model_reasoning_effort`,
  `sandbox_mode`, `mcp_servers`, and `skills.config`.
- **Global Agent Settings (in `config.toml`):**
  - `agents.max_threads`: Concurrent thread cap (default `6`).
  - `agents.max_depth`: Spawning nesting depth (default `1` to prevent recursive
    delegation loops).
  - `agents.job_max_runtime_seconds`: Timeout per worker for CSV batch jobs.

### CSV Batch Processing (Experimental)

- Use `spawn_agents_on_csv` to run audits/reviews of multiple items in parallel
  (one agent per CSV row). Output is aggregated and exported to a target CSV.
  Each worker must report results via `report_agent_job_result`.

**Actionable Advice Output:** Provide the exact `.claude/agents/*.md` definition
with frontmatter (Claude) or custom agent TOML structure (Codex). Explain how
boundary limits prevent context bloating or recursive loops.
