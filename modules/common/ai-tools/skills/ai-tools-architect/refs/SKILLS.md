# Standards for Agent Skills

A skill is a directory with a `SKILL.md`, optionally supported by `scripts/`,
`references/`, and `assets/`. A useful skill can be a short method; it does not
need a workflow or a script to justify itself.

Contents: [Frontmatter](#frontmatter) · [Body](#body) ·
[Portability](#portability) · [Scripts](#scripts) · [Review](#review) ·
[Claude Code](#claude-code) · [Codex](#codex) ·
[GitHub Copilot](#github-copilot)

## Frontmatter

- Use only the Agent Skills fields: `name`, `description`, `license`,
  `compatibility`, `metadata`, and `allowed-tools`. Hosts strip or reject other
  keys, and `skills-ref validate` fails on them. Put host-only settings in
  sidecars such as `agents/openai.yaml`.
- `name`: 1 to 64 characters of lowercase letters, digits, and single hyphens,
  equal to the directory name. Avoid vague names such as `helper` or `utils`,
  and never use `anthropic` or `claude`.
- `description`: up to 1,024 characters. Write one sentence on what the skill
  does, then `Use when ...` with the trigger words first, because hosts shorten
  descriptions under their listing budgets. Put every trigger here, not in the
  body. Make it specific enough to avoid false activation; a vague description
  is fixed by precision, not emphasis.
- `metadata` holds string-to-string pairs with unique key names. Leave
  `compatibility` out unless the skill truly needs a particular environment.
- `allowed-tools` is a host-specific hint: Copilot pre-approves the listed
  tools, Claude Code pre-approves them for one turn without restricting others,
  and Codex does not document it.
- Quote YAML values that contain colons.

## Body

- Keep a root `SKILL.md` under 100 lines: rules, an ordered workflow, and
  routing to references. Upstream allows 500 lines and about 5,000 tokens.
- Write it as a playbook. Use the imperative, one term per concept, and one
  default with a brief escape hatch instead of a menu of equal options.
- Give each workflow step a completion condition that can be checked.
- Add only what the model lacks. Match specificity to fragility: exact commands
  for risky or brittle steps, heuristics for judgment calls.
- Keep gotchas inline where the agent reads them before it hits the situation.
  Prefer a few canonical examples over a list of edge cases.
- State facts directly. Leave out research narrative, test counts, session
  details, and information that will go stale; collect unverified behavior in
  one short list.
- Link references one level deep from `SKILL.md`, say when to load each one, and
  name files for their content. Add a table of contents to any reference over
  100 lines.
- Use forward slashes in paths, even for Windows.
- Never write task output or mutable state into the installed skill directory.
  Use caller-selected paths or temporary directories.
- Nothing in a skill should surprise a user who reads its description.

## Portability

- Keep the skill working outside its host repository. Never reference files in
  that repository, user-home paths, account or tenant names, or personal data;
  the audit flags host-repository and user-home paths.
- Do not trim a portable skill because a repository's instructions repeat its
  rules. Declared skill dependencies can supply shared methods.
- Keep one canonical skill tree. `.agents/skills` (project) and
  `~/.agents/skills` (user) are read by Codex and Copilot; Claude Code reads
  `.claude/skills` and follows symlinks, so link `.claude/skills` to
  `../.agents/skills`. Do not copy a skill into both: some hosts list duplicate
  names twice.
- Mark host-bound skills as host-only and exclude them from publication.
- List the tools and packages a script needs. Run on Linux and macOS, handle
  Windows where feasible, and fall back or report clearly when an optional tool
  is missing.

## Scripts

Keep the agent responsible for intent, ambiguity, choosing the operation, and
interpreting results. Use a script when an operation has defined inputs and
outputs and any of these apply:

- the same query, transformation, validation, or mutation recurs
- correctness depends on exact parsing, ordering, escaping, or API parameters
- generated code would otherwise be rewritten on each run
- a mutation needs consistent safety checks and an auditable result

Skip scripts for one-off exploration or thin wrappers around a stable command.
Say whether the agent should run a script or read it, and invoke it with a path
relative to the skill root. Run trusted bundled scripts without loading their
source; read unknown or external scripts before first use.

### Query Contracts

- Accept explicit arguments or stdin; never prompt for input or depend on
  conversational state.
- Default to read-only behavior and deterministic ordering.
- Send bounded, machine-readable output such as JSON to stdout and diagnostics
  to stderr.
- Expose filters, fields, pagination, and output limits.
- Document exit codes that change the next step: success, no match, invalid
  input, tool or network failure.
- Handle error conditions in the script, and justify every constant.

### Mutation Contracts

- Require the exact target and desired value; never infer destructive scope.
- Preview by default and require `--apply` or equivalent when the API supports a
  meaningful preview.
- Make operations idempotent or detect already-applied state.
- Validate preconditions and fail closed on stale, partial, or ambiguous input.
- Return stable identifiers and a concise change manifest.
- Preserve approval and authorization boundaries.

### Packaging

- Keep scripts self-contained or declare their dependencies.
- Test added scripts with fixtures, including failure and no-op cases for
  mutations.
- Separate query and mutation subcommands when that makes review clearer.
- Refer to MCP tools by fully qualified name, such as `ServerName:tool_name`.

## Review

1. Write at least three evaluation tasks before writing extensive guidance:
   positive and near-miss triggers plus expected outputs and failure modes. For
   trigger tuning, use about 20 queries split between tuning and holdout.
2. Decide which steps need judgment, an existing tool, or a script.
3. Route detail to references, reusable material to assets, and exact mechanics
   to scripts.
4. Validate frontmatter, links, provider metadata, and every script. Run the
   audit and `skills-ref validate <skill-dir>` where available.
5. Test in a fresh session with and without the skill; leftover authoring
   context hides gaps. Test on each model the skill targets. See
   [workflow-evaluation.md](workflow-evaluation.md).

## Claude Code

- Discovery precedence: enterprise, personal (`~/.claude/skills`), project
  (`.claude/skills`); nested directories and plugin skills also load. Commands
  are skills.
- Unknown frontmatter fields are ignored silently, so a typo disables a setting
  without error. Skill fields are hyphenated.
- `disable-model-invocation: true` removes the description from context; use it
  for workflows with side effects or deliberate timing. It is outside the Agent
  Skills fields, so pair it with the repository's cross-host invocation metadata
  and accept the `skills-ref` warning, or gate the skill another way.
- Reference bundled files with `${CLAUDE_SKILL_DIR}`. `paths` limits automatic
  loading to matching files. `context: fork` runs the skill in a subagent that
  sees no conversation history, so it needs explicit instructions.
- After compaction, Claude Code keeps the first 5,000 tokens of each recently
  invoked skill within a 25,000-token total. Put essential guidance first.
- Move a rule that must hold every time into a hook; skill text is advisory.
- Cheap discovery check from the repository root:
  `claude -p "Reply with only available skill names containing X, or NONE." --max-turns 1`.

## Codex

- Discovery: `.agents/skills` in each directory from the working directory up to
  the repository root, `~/.agents/skills`, and `/etc/codex/skills`. Symlinks are
  followed; duplicate names are not merged.
- The initial skills list gets 2% of the context window, or 8,000 characters
  when the window is unknown; Codex shortens descriptions first, then drops
  skills.
- `agents/openai.yaml` holds `interface` (display name, short description,
  icons, default prompt), `policy.allow_implicit_invocation`, and
  `dependencies.tools` for MCP. With implicit invocation off, `$skill` still
  works.
- Disable a skill with `[[skills.config]]`, `path`, and `enabled = false` in
  `~/.codex/config.toml`.
- Codex custom prompts are deprecated; write skills instead.

## GitHub Copilot

- Discovery: `.github/skills`, `.claude/skills`, and `.agents/skills` in the
  repository; `~/.copilot/skills` and `~/.agents/skills` for the user. Claude
  skills work unchanged.
- Documented fields are `name`, `description`, and `license`; `allowed-tools`
  pre-approves Copilot tool names such as `shell`. Only pre-approve shell tools
  for reviewed skills.
- Invoke explicitly with `/name` in the CLI and refresh with `/skills reload`.
  `gh skill publish --dry-run` validates against the Agent Skills specification.
- Use custom instructions for short rules that apply to almost every task and
  skills for task-specific workflows.

## Invocation Policy

- Record cross-provider user-only intent in `metadata` with a namespaced key,
  and add `disable-model-invocation: true` for Claude Code and Copilot. Set
  `policy.allow_implicit_invocation: false` in `agents/openai.yaml` for Codex.
  Validate that these declarations agree.
- A skill that another skill must invoke cannot be user-only; hide it from Codex
  implicit matching only with the `agents/openai.yaml` policy.
- Do not remove a useful route or make skills explicit-only merely to fit a
  description budget.
