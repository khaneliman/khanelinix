{ lib, ... }:
let
  agentsBasePath = ./agents;
  modelValue = provider: model: if builtins.isAttrs model then model.${provider} or null else model;

  agents = {
    "fact-finder" = {
      name = "fact-finder";
      description = "Read-only fact-finding specialist for scoped repo questions. Use for multi-file discovery, caller tracing, config lookup, pattern comparison, and bounded evidence gathering when main context should stay small.";
      tools = [
        "Read"
        "Bash"
        "Grep"
        "Glob"
      ];
      model = {
        claude = "haiku";
        copilot = "claude-haiku-4.5";
        opencode = "openai/gpt-5.6-luna";
        codex = "gpt-5.6-luna";
      };
      model_reasoning_effort = {
        codex = "medium";
      };
      sandbox_mode = {
        codex = "read-only";
      };
      content = builtins.readFile (agentsBasePath + "/general/fact-finder.md");
    };
    "probe-runner" = {
      name = "probe-runner";
      description = "Bounded probe and reproduction specialist. Use for one-shot commands, non-destructive checks, reproduction attempts, browser probes, eval/build probes, and noisy output summaries.";
      tools = [
        "Read"
        "Bash"
        "Grep"
        "Glob"
      ];
      model = {
        claude = "haiku";
        copilot = "claude-haiku-4.5";
        opencode = "openai/gpt-5.6-luna";
        codex = "gpt-5.6-luna";
      };
      model_reasoning_effort = {
        codex = "medium";
      };
      sandbox_mode = {
        codex = "workspace-write";
      };
      content = builtins.readFile (agentsBasePath + "/general/probe-runner.md");
    };
    debugger = {
      name = "debugger";
      description = "Read-only root-cause specialist for a reproduced error, exception, test failure, or unexpected behavior with supplied symptom or evidence.";
      tools = [
        "Read"
        "Bash"
        "Grep"
        "Glob"
      ];
      model = {
        claude = "sonnet";
        copilot = "claude-sonnet-4.6";
        opencode = "openai/gpt-5.6-sol";
        codex = "gpt-5.6-sol";
      };
      model_reasoning_effort = {
        codex = "medium";
      };
      sandbox_mode = {
        codex = "read-only";
      };
      content = builtins.readFile (agentsBasePath + "/general/debugger.md");
    };
    refactorer = {
      name = "refactorer";
      description = "Code refactoring specialist for improving code structure, readability, and maintainability without changing behavior. Use for focused refactoring tasks in isolated context.";
      tools = [
        "Read"
        "Edit"
        "Write"
        "Grep"
        "Glob"
        "Bash"
      ];
      model = {
        claude = "sonnet";
        copilot = "claude-sonnet-4.6";
        opencode = "openai/gpt-5.6-terra";
        codex = "gpt-5.6-terra";
      };
      model_reasoning_effort = {
        codex = "medium";
      };
      permission = {
        edit = "ask";
      };
      content = builtins.readFile (agentsBasePath + "/general/refactorer.md");
    };
    test-runner = {
      name = "test-runner";
      description = "Test execution specialist. Use for broad or noisy tests, checks, lint, build validation, failure analysis, and post-change verification. Keeps verbose output out of main conversation.";
      tools = [
        "Read"
        "Bash"
        "Grep"
        "Glob"
      ];
      model = {
        claude = "haiku";
        copilot = "claude-haiku-4.5";
        opencode = "openai/gpt-5.6-luna";
        codex = "gpt-5.6-terra";
      };
      sandbox_mode = {
        codex = "workspace-write";
      };
      content = builtins.readFile (agentsBasePath + "/general/test-runner.md");
    };
  };

  renderClaudeFrontmatter = agent: ''
    ---
    name: ${agent.name}
    description: ${agent.description}
    tools: ${lib.concatStringsSep ", " agent.tools}
    model: ${agent.model.claude or agent.model}
    ---
  '';

  renderClaudeAgent = agent: ''
    ${lib.trim (renderClaudeFrontmatter agent)}

    ${lib.trim agent.content}
  '';

  renderOpenCodeTools =
    agent:
    let
      allowed = map lib.toLower agent.tools;
      isAllowed = tool: lib.elem tool allowed;
      coreTools = [
        "bash"
        "edit"
        "write"
      ];
      coreToolLines = map (tool: "  ${tool}: ${if isAllowed tool then "true" else "false"}") coreTools;
    in
    lib.concatStringsSep "\n" coreToolLines;

  renderOpenCodePermission =
    permission:
    if permission == null then
      ""
    else
      let
        render = key: value: "  ${key}: ${toString value}";
      in
      ''
        permission:
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList render permission)}
      '';

  renderOpenCodeFrontmatter = agent: ''
    ---
    description: ${agent.description}
    mode: ${agent.mode or "all"}
    model: ${agent.model.opencode or agent.model}

    tools:
    ${renderOpenCodeTools agent}
    ${renderOpenCodePermission (agent.permission or null)}
    ---
  '';

  renderOpenCodeAgent = agent: ''
    ${lib.trim (renderOpenCodeFrontmatter agent)}

    ${lib.trim agent.content}
  '';

  renderCopilotFrontmatter =
    agent:
    let
      model = if builtins.isAttrs agent.model then agent.model.copilot or null else agent.model;
    in
    ''
      ---
      name: ${builtins.toJSON agent.name}
      description: ${builtins.toJSON agent.description}
      ${lib.optionalString (model != null) "model: ${builtins.toJSON model}"}
      ---
    '';

  renderCopilotAgent = agent: ''
    ${lib.trim (renderCopilotFrontmatter agent)}

    ${lib.trim agent.content}
  '';

  renderCodexAgent =
    agent:
    let
      model = modelValue "codex" agent.model;
      modelReasoningEffort = modelValue "codex" (agent.model_reasoning_effort or null);
      sandboxMode = modelValue "codex" (agent.sandbox_mode or null);
    in
    {
      inherit (agent) name;
      inherit (agent) description;
      developer_instructions = lib.trim agent.content;
    }
    // lib.optionalAttrs (model != null) {
      inherit model;
    }
    // lib.optionalAttrs (modelReasoningEffort != null) {
      model_reasoning_effort = modelReasoningEffort;
    }
    // lib.optionalAttrs (sandboxMode != null) {
      sandbox_mode = sandboxMode;
    }
    // lib.optionalAttrs (agent ? nickname_candidates) {
      inherit (agent) nickname_candidates;
    };

  toClaudeMarkdown = lib.mapAttrs (_name: renderClaudeAgent) agents;
  toCopilotMarkdown = lib.mapAttrs (_name: renderCopilotAgent) agents;
  toCodexAgents = lib.mapAttrs (_name: renderCodexAgent) agents;
  toOpenCodeMarkdown = lib.mapAttrs (_name: renderOpenCodeAgent) agents;
in
{
  inherit
    agents
    renderClaudeAgent
    renderCopilotAgent
    renderOpenCodeAgent
    toClaudeMarkdown
    toCopilotMarkdown
    toCodexAgents
    toOpenCodeMarkdown
    ;
}
