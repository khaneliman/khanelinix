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
