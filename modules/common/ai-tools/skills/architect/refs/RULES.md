# Standards for Path-Gated Rules

When advising the user on creating rules, enforce the following constraints to
ensure maximum token efficiency and safety.

> [!IMPORTANT]
> "Rules" are different mechanisms per platform. Claude rules are path-gated
> context/style guidance. Codex `.rules` files are command execution policy for
> the sandbox. For directory-scoped _guidance_ on Codex, use nested `AGENTS.md`
> files instead — see [AGENTS.md](AGENTS.md).

## Claude-Specific Rules

1. **Default to Path-Gating:** Instruct the user to bind the rule to a specific
   directory or file extension (e.g., `*.rs`, `flake.nix`, `src/frontend/`) so
   it loads only when relevant. Leave a rule unscoped only when it must apply
   universally or survive compaction (see Context Behaviors below).
2. **Context Isolation:** The rule should only contain conventions, syntax
   formatting, or architectural constraints relevant to that specific path.
3. **No Tool Logic:** Rules dictate _how_ to write code or format output; they
   should not instruct the LLM on _which_ tools to use. Tool orchestration
   belongs in Subagents or Skills.

### Context Behaviors

- **Compaction Loss:** Rules with `paths:` frontmatter and nested `CLAUDE.md`
  files load into message history when their trigger file is read. Therefore,
  when the session compacts, they are summarized away. They will only reload
  once a matching file is read again.
- **Persistent Rules:** If a rule must persist across compaction, instruct the
  user to drop the `paths:` frontmatter or move it to the project-root
  `CLAUDE.md`.

---

## Codex Rules (.rules)

Codex uses `.rules` files to control which commands can be run outside the
sandbox.

### Design Guidelines

- **Locations:** Scanned at startup under `~/.codex/rules/` (user layer) and
  `<repo>/.codex/rules/` (project layer, loaded only if trusted).
- **Format:** Written in Starlark (Python-like safe dialect).
- **Core Function:** Uses `prefix_rule(...)` to match command argument lists.
- **Conflict Resolution:** When multiple rules match a command, the most
  restrictive decision wins.
- **TUI Writes:** Commands the user allows interactively are persisted as
  `prefix_rule` entries in `~/.codex/rules/default.rules`; review these when
  auditing the user layer.

```python
prefix_rule(
    pattern = ["gh", "pr", "view"],
    decision = "prompt", # "allow" | "prompt" | "forbidden"
    justification = "Viewing PRs is allowed with approval",
    match = ["gh pr view 7888"],
    not_match = ["gh pr --repo openai/codex view 7888"],
)
```

### Shell Wrappers and Splitting

- **Safe Splitting:** Linear chains of commands using only plain words (no vars,
  wildcards) joined by safe operators (`&&`, `||`, `;`, `|`) are split and
  checked individually (e.g. `git add . && rm -rf /` checks both).
- **Unsplit Compound:** Commands using env vars, redirects (`>`, `<`),
  substitutions (`$(...)`), wildcards (`*`), or control flow (`if`, `for`) are
  treated as a single invocation (e.g. `["bash", "-c", "..."]`) and evaluated as
  one unit.

### Testing Rules

- Test policies using:
  ```shell
  codex execpolicy check --pretty --rules <rule_file> -- <command>
  ```

**Actionable Advice Output:** When proposing a rule, specify the exact
path-gating syntax (Claude) or `prefix_rule` Starlark syntax (Codex), explain
the security implication, and specify how it reduces global context overhead.
