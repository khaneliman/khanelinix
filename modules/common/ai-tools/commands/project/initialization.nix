let
  commandName = "initialization";
  description = "Analyze a repository and create or improve AGENTS.md for AI coding assistants";
  allowedTools = "Read, Grep, Glob, Write, Edit";
  argumentHint = "[path]";
  prompt = ''
    Analyze target repo (`[path]` or current directory) and create or improve
    `AGENTS.md` for AI coding agents.

    Required first text:

    ```
    This file provides guidance to AI coding agents like Claude Code (claude.ai/code), Cursor AI, Codex, Antigravity CLI, GitHub Copilot, and other AI coding assistants when working with code in this repository.
    ```

    Include:
    1. Common build, lint, test, run, and single-test commands.
    2. High-level architecture that requires reading multiple files to learn.
    3. Important existing guidance from Cursor rules, AGENTS/CLAUDE/GEMINI docs,
       Copilot instructions, README, or PROJECT docs.

    Constraints:
    - If `AGENTS.md` exists, improve or suggest improvements; do not replace
      blindly.
    - Keep under 500 lines.
    - Avoid generic practices, obvious directory listings, and invented sections.
    - Write focused, actionable, scoped internal-doc rules.

    Deliverable: update/create `AGENTS.md` and summarize what changed and why.
  '';

in
{
  ${commandName} = {
    inherit
      commandName
      description
      allowedTools
      argumentHint
      prompt
      ;
  };
}
