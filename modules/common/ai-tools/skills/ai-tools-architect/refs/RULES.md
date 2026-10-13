# Standards for Instruction Files and Path-Gated Rules

Instruction files load on every turn or whenever their path matches, so every
line is a recurring cost. "Rules" also mean different things per host: Claude
rules are path-gated guidance, while Codex `.rules` files are command execution
policy.

## Writing Instruction Files

- Keep each always-loaded file short; for `CLAUDE.md`, stay under 200 lines.
  Codex stops adding `AGENTS.md` text past 32 KiB by default.
- Write short, concrete, verifiable statements. Test each line: would removing
  it cause a mistake? Leave out what the agent can learn from the code.
- Use emphasis rarely; when many lines are emphasized, none stands out.
- Remove contradictions; an agent may pick either side.
- Move procedures into skills and area-specific notes into path-gated rules or
  nested files. Imports do not reduce context cost.
- Rules state how to write code or format output, not which tools to call; tool
  orchestration belongs in skills and agents.

## Claude Code

- Path-gate rules with `paths:` frontmatter (for example `*.rs` or
  `src/frontend/`) so they load only when relevant. Leave a rule unscoped only
  when it must apply everywhere.
- Path-gated rules and nested `CLAUDE.md` files load when a matching file is
  read and are summarized away at compaction; they reload only when a matching
  file is read again. Move a rule that must survive compaction to the root
  `CLAUDE.md`.
- `CLAUDE.md` arrives as a user message after the system prompt. Claude Code
  also loads `AGENTS.md` where it would load `CLAUDE.md`, but only when no
  project `CLAUDE.md` exists; see [INITIALIZATION.md](INITIALIZATION.md).

## Codex Instruction Chain (AGENTS.md)

- Global scope: `~/.codex/AGENTS.override.md`, then `~/.codex/AGENTS.md`; only
  the first non-empty file loads.
- Project scope: from the repository root down to the working directory, each
  directory contributes at most one of `AGENTS.override.md`, `AGENTS.md`, or a
  name in `project_doc_fallback_filenames`.
- Files are concatenated root first, so closer files override earlier ones. Past
  `project_doc_max_bytes` (32 KiB by default), Codex adds no more files; raise
  the cap or move guidance into nested directories.

## GitHub Copilot

- `.github/copilot-instructions.md` applies repository-wide.
  `.github/instructions/*.instructions.md` files apply by `applyTo` glob and
  combine with the repository-wide file; `excludeAgent` limits which agents read
  them.
- The nearest `AGENTS.md` takes precedence; a root `CLAUDE.md` or `GEMINI.md`
  also works. Support differs by surface: the cloud agent and CLI read all
  three, VS Code Chat reads `AGENTS.md`.

## Codex Command Rules (.rules)

- Codex reads `.rules` files from `~/.codex/rules/` and, in trusted projects,
  `<repo>/.codex/rules/`. They are Starlark and decide which commands may run
  outside the sandbox. The most restrictive matching decision wins, and commands
  approved in the TUI are saved to `~/.codex/rules/default.rules`.

```python
prefix_rule(
    pattern = ["gh", "pr", "view"],
    decision = "prompt", # "allow" | "prompt" | "forbidden"
    justification = "Viewing PRs is allowed with approval",
    match = ["gh pr view 7888"],
    not_match = ["gh pr --repo openai/codex view 7888"],
)
```

- Plain command chains joined by `&&`, `||`, `;`, or `|` are split and checked
  one by one. Commands with variables, redirects, substitutions, wildcards, or
  control flow are checked as one `bash -c` invocation.
- Test a policy with
  `codex execpolicy check --pretty --rules <rule_file> -- <command>`.

## Output

Give the exact path-gating syntax or `prefix_rule` for the target host, its
security effect, and how it reduces always-loaded context.
