# Knowledge workspace

This workspace uses portable Markdown for `zk`, Obsidian, and Pandoc.

## Format contract

- Use YAML frontmatter for structured metadata.
- Use relative Markdown links instead of wiki links.
- Store images and other attachments under `Attachments/`.
- Use standard fenced code blocks.
- Do not depend on Obsidian embeds, callouts, or plugin-specific task syntax.
- Treat Markdown checklists as capture items. Track actionable work in
  Taskwarrior or the team backlog.

## Directories

- `Daily/`: daily capture and follow-up
- `Decisions/`: architecture and project decisions
- `Meetings/`: meeting context, notes, decisions, and actions
- `Projects/`: project outcomes, scope, risks, and milestones
- `Requirements/`: requirements and acceptance criteria
- `Templates/`: writable starter templates for Obsidian

## Configuration ownership

- Home Manager copies this README and starter templates only when absent.
- Home Manager owns configured `.obsidian/*.json` settings as store symlinks.
- Change declarative Obsidian settings in the Home Manager module.
