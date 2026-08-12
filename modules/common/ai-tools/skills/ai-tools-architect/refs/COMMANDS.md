# Standards for Single-File Commands

Commands are atomic, single-shot prompt templates designed for specific,
non-interactive tasks (e.g., refactoring a single file, generating a commit
message).

## Design Constraints

1. **Atomic Purpose:** A command must do exactly one thing (e.g., format a
   docstring, extract a Nix option). No multi-step orchestrations.
2. **Strict Input/Output Contracts:** Define exact inputs (e.g. `$FILE`,
   `$DIFF`) and the required output format (e.g. "output only the raw patched
   code block, no markdown wraps").
3. **Zero Interactivity:** Commands are built for batch or pipeline execution;
   they must never ask the user questions.
4. **Stateless Transformation:** Treat commands as pure functions:
   `f(context, input) -> output`.
5. **Context Cleanliness:** Do not include global instructions or system prompt
   replicas. Keep the prompt focused entirely on the transformation.

## Claude-Specific Context Behaviors

- **Prompt Caching Efficiency:** Because commands are atomic and execute in one
  shot, they benefit heavily from prompt caching. Keeping command prompts static
  and input variables clearly delineated at the end ensures that the rest of the
  template remains cached, minimizing token cost and latency.

**Actionable Advice Output:** Provide the raw command prompt structure, specify
the exact input/output boundaries, and show how the command can be integrated
into the tool runner.
