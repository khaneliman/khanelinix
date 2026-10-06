# Standards for Agent Skills

Skills supply task-specific guidance in a directory containing `SKILL.md`,
optionally supported by scripts, assets, and references. A useful skill can be a
short method; it does not need a multi-step workflow or a script to justify
itself.

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

## When to Use a Script

Keep the agent responsible for intent, ambiguity, choosing the operation, and
interpreting its result. Prefer a script when an operation has defined inputs
and outputs and any of these apply:

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
2. Decide which steps need judgment, an existing tool, or a script for exact
   repeated mechanics. Do not prescribe a fixed sequence when several approaches
   can meet the task's constraints.
3. Route detailed knowledge to references, reusable output material to assets,
   and exact repeated mechanics to scripts.
4. Validate frontmatter, links, resource reachability, provider metadata, and
   every added script.
5. Evaluate complex skills on realistic requests with fresh context. Pass raw
   task artifacts, not intended answer or suspected defect.

---

## Claude Code Context Behavior

Claude Code discovers repository skills under `.claude/skills` and follows
symlinks, including a directory symlink `.claude/skills -> ../.agents/skills`.
Keep one canonical tree in `.agents/skills` to serve both Claude Code and Codex
without copied skill files.

For a cheap discovery check, run from the repository root with the intended
configuration:

```sh
claude -p "Reply with only available skill names containing X, or NONE." \
  --max-turns 1
```

Use a distinctive skill-name fragment in place of `X`. This creates ordinary
session history; recheck discovery after major CLI updates.

The
[Claude Code skill documentation](https://code.claude.com/docs/en/skills#skill-content-lifecycle)
describes reattaching the most recent invocation of each skill after compaction:
the first **5,000 tokens per skill**, within a **25,000-token combined budget**,
starting with the most recently invoked skill. Older skills can be omitted.
These are post-compaction retention limits, not initial skill-loading caps or
portable authoring requirements. Put essential guidance near the start and load
supporting detail only when needed. Recheck provider behavior when a version
change matters; a short entry point does not guarantee retained context.

---

## Codex Agent Skills

Codex supports the
[Agent Skills standard](https://agentskills.io/specification). Use the
[official skills documentation](https://learn.chatgpt.com/docs/build-skills) for
current discovery locations and provider behavior.

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

### Discovery Budget and Repository Check

- The official documentation gives the initial skills list **2% of the model's
  context window**, or **8,000 characters when the window is unknown**. It
  includes names, descriptions, and paths. Codex shortens descriptions first and
  may omit skills when the list still does not fit. This does not cap the body
  read after a skill is selected.
- This repository's structural audit separately enforces a configurable
  **7,800-character default ceiling for implicitly invocable descriptions**. It
  exits nonzero on overflow. This is a conservative local check, not a
  measurement of the full rendered list or a guarantee that every host fits.
- Front-load the key use case and keep descriptions specific. Do not remove
  useful routes or make skills explicit-only merely to reach a number.
- Disable specific skills in `~/.codex/config.toml` using:
  ```toml
  [[skills.config]]
  path = "/path/to/skill/SKILL.md"
  enabled = false
  ```

### Invocation Policy

- Record cross-provider user-only intent as
  `metadata.khanelinix-invocation-mode: "user-only"` in canonical skills.
- For a directly published user-only skill, keep
  `disable-model-invocation: true` beside that metadata so Claude preserves the
  gate without a generated copy. Validate that both declarations agree. Codex
  uses `agents/openai.yaml` for the same gate. Keep the source directly
  installable instead of generating provider-specific skill copies.
- Set `policy.allow_implicit_invocation: false` in `agents/openai.yaml` for each
  user-only skill.
- Codex can also hide caller-invoked methods. Do not emit a user-only host flag
  when another skill must invoke that method.
- Codex-explicit skills set only the `agents/openai.yaml` policy and keep no
  cross-provider flag. Caller-only owners such as `arena` and `recall` use this
  tier. Claude and Pi still match their trigger phrases; Codex reaches them by
  name. This asymmetry is deliberate and protects the Codex discovery budget.
- Validate canonical intent, native controls, and publication paths as one
  contract.

When proposing a skill, show the smallest useful package and explain when it
applies. Draft frontmatter, provider metadata, or script contracts only where
the change needs them. Check the repository's description budget without
treating it as a universal provider limit or creating unnecessary scaffolding.
