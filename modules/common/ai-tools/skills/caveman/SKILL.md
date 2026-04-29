---
name: caveman
description: >
  Consolidates ultra-compressed communication, commit-message generation, PR review
  notes, and memory compression into one progressive-disclosure skill.
---

# Caveman Toolkit

Use when the user asks for concise communication or any of the following
workflows:

- reduced-token wording
- commit message generation
- PR review comments
- memory file compression

## How I choose what to do (progressive disclosure)

1. **communication** — default for brevity requests.
2. **commit-message** — terse commit message generation.
3. **compress** — compress memory/prose files (`CLAUDE.md`, notes, docs).
4. **review** — one-line PR review comments.

If intent is unclear, ask for the mode before applying work.

## 1) Communication Mode

Default tone mode. Be terse, keep technical substance, cut filler.

### Default behavior

- Active by default once this skill is used.
- Revert to normal style only if user says `stop caveman` or `normal mode`.
- Default intensity: `full`.
- Change intensity with:
  - `/caveman lite`
  - `/caveman full`
  - `/caveman ultra`
  - `/caveman wenyan-lite`
  - `/caveman wenyan-full`
  - `/caveman wenyan-ultra`

### Rules

- Drop: articles, filler, pleasantries, hedging.
- Keep technical terms exact.
- Keep code blocks and quoted errors verbatim.
- One-line structure preferred:
  - `[thing] [action] [reason]. [next step].`
- Prefer short synonyms and fragments over prose.

### Auto-Clarity Override

Drop caveman mode for:

- security warnings
- irreversible actions
- unclear multi-step instructions
- clarification-heavy user exchanges

Switch back once that segment is complete.

Example:

```text
This will permanently delete all rows in `users`. Cannot be undone.
DROP TABLE users;
Confirm backup exists before proceeding.
```

## 2) Commit Message Mode

Generate concise Conventional Commit messages.

- Trigger: user says “write a commit”, “commit message”, `/commit`, or
  `/caveman-commit`.
- Scope: commit message text only; do not run commit commands.

### Format

- `<type>(<scope>): <imperative summary>` (scope optional)
- Subject ≤50 chars when possible, hard cap 72.
- No trailing period.
- No fluff.

Allowed types:
`feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `chore`, `build`, `ci`,
`style`, `revert`.

### Body

Include only when needed:

- non-obvious why
- breaking changes
- migration notes
- linked issue references

Reference format:

- `Closes #42`
- `Refs #17`

Use bullets (`-`) and wrap at ~72 chars.

## 3) Compress Mode

Convert long natural-language files into caveman style.

- Trigger: `/caveman:compress <filepath>`, “compress memory file”, or explicit file
  compression request.
- Scope: `.md`, `.txt`, `.rst`, extensionless prose files.
- Skip code/config files and `.original.md` backups.

### Procedure

1. Confirm explicit filepath.
2. Run compression:
   - `cd "<path-to-skill>" && python3 -m scripts <absolute_filepath>`
3. Confirm output:
   - `<file>` compressed
   - `<file>.original.md` backup

### Preserve exactly

- fenced/indented code blocks
- inline code
- links/URLs
- paths and commands
- technical terms, headings, tables, dates/numbers

### Boundaries

- If input is non-prose or uncertain, do not modify it.

Supporting docs:

- [README-compress.md](README-compress.md)
- [SECURITY-compress.md](SECURITY-compress.md)

## 4) Review Mode

Write review findings in one-line format for PR code feedback.

- Trigger: `review this PR`, `/review`, `/caveman-review`.

### Format

- `<file>:L<line>: <problem>. <fix>.`
- Optional severity prefixes:
  - `🔴 bug`
  - `🟡 risk`
  - `🔵 nit`
  - `❓ q`

### Rules

- Keep exact symbol/line references.
- Concrete fix over abstraction.
- No throat-clearing.
- Avoid fluff and repeated praise.

### Boundaries

- Do not patch code.
- Output comments only, ready to paste.
