let
  commandName = "initialization";
  description = "Analyze a repository and create or improve AGENTS.md for AI coding assistants";
  allowedTools = "Read, Grep, Glob, Write, Edit";
  argumentHint = "[path]";
  prompt = ''
    Please analyze this codebase and create an `AGENTS.md` file, which will be given to future instances of this AI coding agent (like Claude Code, Codex or Gemini CLI) a simple set of rules to operate in this project.

    Target path: use `[path]` if provided, otherwise use the current working directory.

    Required header (must be the first text in the file):

    ```
    This file provides guidance to AI coding agents like Claude Code (claude.ai/code), Cursor AI, Codex, Gemini CLI, GitHub Copilot, and other AI coding assistants when working with code in this repository.
    ```

    What to add:
    1. Commands that will be commonly used, such as how to build, lint, and run tests. Include the necessary commands to develop in this codebase, such as how to run a single test.
    2. High-level code architecture and structure so future agents can become productive quickly. Focus on big-picture architecture that requires reading multiple files to understand.

    Usage notes:
    - If there is already an `AGENTS.md`, suggest improvements to it instead of replacing it.
    - For initial `AGENTS.md` creation, avoid repetition and avoid obvious generic advice.
    - Avoid listing every component or file structure that can be easily discovered.
    - Do not include generic development practices.
    - If there are Cursor rules (`.cursor/rules/` or `.cursorrules`), AGENTS/CLAUDE/GEMINI docs, or Copilot rules (`.github/copilot-instructions.md`), include the important parts.
    - If there is a `README.md` or `PROJECT.md`, include important relevant parts.
    - Do not invent sections such as "Common Development Tasks", "Tips for Development", or "Support and Documentation" unless these are explicitly present in repository docs.

    Best practices:
    - Write focused, actionable, scoped rules.
    - Keep `AGENTS.md` under 500 lines.
    - Avoid vague guidance; prefer clear internal-doc style rules.
    - Reuse stable rules from previous prompts when appropriate.

    Deliverable:
    - Update or create `AGENTS.md` in the target repository.
    - Provide a short summary of what was added or improved and why.
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
