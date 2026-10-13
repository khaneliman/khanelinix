# Standards for Commands and Prompt Files

Commands are one-shot prompt templates for a single, non-interactive
transformation, such as generating a commit message.

## Choose the Format

- Write a skill for anything reusable across hosts. Claude Code treats commands
  as skills, Codex custom prompts are deprecated in favor of skills, and Copilot
  prompt files (`.github/prompts/*.prompt.md`) work only in IDEs.
- Keep a host-specific command or prompt file only when that host is the sole
  consumer.

## Design Constraints

1. **Atomic purpose.** Do exactly one thing; no multi-step orchestration.
2. **Strict input and output.** Name the inputs, such as `$FILE` or `$DIFF`, and
   the exact output format.
3. **No interaction.** Never ask the user questions; commands run in batches and
   pipelines.
4. **Stateless.** Treat the command as `f(context, input) -> output`.
5. **Focused context.** Leave out global instructions and system-prompt copies.

Keep the template static with inputs at the end so the rest stays in the prompt
cache.

## Output

Give the prompt structure, its input and output boundaries, and how it plugs
into the tool runner.
