# Standards for Agent Skills

Skills are reusable, multi-step workflows package-managed as directories
containing a `SKILL.md` playbook, optionally supported by scripts, assets, and
references.

## Design Constraints

1. **Lean Playbook:** Target a root `SKILL.md` under 100 lines. Focus on
   triggers, high-level workflow steps, and execution routing; split before the
   [open-standard 500-line recommendation](https://agentskills.io/specification#progressive-disclosure)
   becomes relevant.
2. **On-Demand Loading:** Place detailed manuals, syntax examples, checklists,
   and edge-cases in a `references/` or `refs/` directory. Instruct the AI to
   read them only when relevant.
3. **Executable Automation:** Move deterministic, fragile, or repeated
   operations into `scripts/` instead of asking the model to recreate commands
   or code from prose.
4. **Precise Triggers:** Use specific frontmatter descriptions to prevent
   false-positive activation during generic tasks.
5. **No Package State:** Do not write task outputs or mutable state into the
   installed skill directory. Use explicit caller-selected paths or temporary
   directories.

## Deterministic Execution Boundary

Keep model responsible for intent, ambiguity, operation selection, and result
interpretation. Prefer a script when operation has defined inputs and outputs
and any of these apply:

- same query, transformation, validation, or mutation will recur
- correctness depends on exact parsing, ordering, escaping, or API parameters
- generated code would otherwise be rewritten on each invocation
- mutation needs consistent safety checks and an auditable result
- same inputs should produce same normalized output

Do not add a script for one-off exploratory reasoning or a thin wrapper around a
stable command unless the wrapper creates a useful contract.

### Query Contracts

- Accept explicit arguments or stdin. Never depend on hidden conversational
  state.
- Default to read-only behavior and deterministic ordering.
- Emit bounded, machine-readable output such as JSON or JSONL when downstream
  reasoning needs structured data. Put diagnostics on stderr.
- Expose filters, fields, pagination, and output limits so query does not flood
  model context.
- Use documented exit codes for success, no matches, invalid input, and tool or
  network failure when distinction changes next step.

### Mutation Contracts

- Require exact target and desired value. Do not infer destructive scope inside
  script.
- Default mutation scripts to preview and require explicit `--apply` or
  equivalent when API supports meaningful preview.
- Make operation idempotent or detect already-applied state.
- Validate preconditions and fail closed on stale, partial, or ambiguous input.
- Return stable identifiers plus concise change manifest for readback.
- Preserve agent approval and authorization boundaries; script must not bypass
  them.

### Script Packaging

- Keep script self-contained or declare dependencies and environment needs.
- Route exact invocation from `SKILL.md` or reachable reference using path
  relative to skill root.
- Test added scripts with representative fixtures, including failure and
  no-op/idempotent cases for mutations.
- Prefer separate query and mutation subcommands or scripts when separation
  makes permissions and review clearer.
- Execute trusted bundled scripts without loading source into context. Inspect
  unknown or externally sourced scripts before first execution; read source
  again for debugging or environment-specific patching.

## Skill Review Workflow

1. Collect concrete trigger and non-trigger requests, expected outputs, and
   important failure modes.
2. Mark each workflow step as high-freedom model judgment, direct tool use, or
   low-freedom deterministic script.
3. Route detailed knowledge to references, reusable output material to assets,
   and exact repeated mechanics to scripts.
4. Validate frontmatter, links, resource reachability, provider metadata, and
   every added script.
5. Forward-test complex skills on realistic requests with fresh context. Pass
   raw task artifacts, not intended answer or suspected defect.

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
- This repository enforces a **7,000-character ceiling** to retain margin below
  that approximate host cap.
- If budget is exceeded, Codex shortens descriptions first, then omits skills.
- **Design Rule:** Front-load key use cases and trigger words in the description
  frontmatter so matching works even when truncated.
- Disable specific skills in `~/.codex/config.toml` using:
  ```toml
  [[skills.config]]
  path = "/path/to/skill/SKILL.md"
  enabled = false
  ```

### Invocation Policy

- Record cross-provider user-only intent as
  `metadata.khanelinix-invocation-mode: "user-only"` in canonical skills.
- Emit host-only frontmatter through provider projections. Keep canonical
  packages valid against the Agent Skills specification.
- Set `policy.allow_implicit_invocation: false` in `agents/openai.yaml` for each
  user-only skill.
- Codex can also hide caller-invoked methods. Do not emit a user-only host flag
  when another skill must invoke that method.
- Codex-explicit skills set only the `agents/openai.yaml` policy and keep no
  cross-provider flag. Caller-only owners such as `arena` and `recall` use this
  tier. Claude and Pi still match their trigger phrases; Codex reaches them by
  name. This asymmetry is deliberate and protects the Codex discovery budget.
- Validate canonical intent, provider projection, and publication parity as one
  contract.

**Actionable Advice Output:** Propose the directory structure, draft the
`SKILL.md` frontmatter, draft any `agents/openai.yaml` dependencies, and suggest
trigger words to keep under the 7,000-character repository ceiling. Identify
each workflow step as model judgment, direct tool use, or bundled deterministic
script, and define script input/output and mutation-safety contracts.
