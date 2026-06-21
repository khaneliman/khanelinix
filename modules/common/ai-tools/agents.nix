{ lib, ... }:
let
  agentsBasePath = ./agents;
  modelValue = provider: model: if builtins.isAttrs model then model.${provider} or null else model;

  agents = {
    debugger = {
      name = "debugger";
      description = "Debugging specialist for errors, exceptions, test failures, and unexpected behavior. Use when encountering any issues that need root cause analysis.";
      tools = [
        "Read"
        "Edit"
        "Bash"
        "Grep"
        "Glob"
      ];
      model = {
        claude = "sonnet";
        copilot = "claude-sonnet-4.6";
        antigravity = "gemini-3.1-pro-preview";
        opencode = "openai/gpt-5.5";
        codex = "gpt-5.5";
      };
      permission = {
        edit = "ask";
        bash = "ask";
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
        antigravity = "gemini-3.1-pro-preview";
        opencode = "openai/gpt-5.5";
        codex = "gpt-5.5";
      };
      permission = {
        edit = "ask";
        bash = "ask";
      };
      content = builtins.readFile (agentsBasePath + "/general/refactorer.md");
    };
    test-runner = {
      name = "test-runner";
      description = "Test execution specialist. Use after code changes to run tests, analyze failures, and suggest fixes. Keeps verbose test output out of main conversation.";
      tools = [
        "Read"
        "Bash"
        "Grep"
        "Glob"
        "Edit"
      ];
      model = {
        claude = "haiku";
        copilot = "claude-haiku-4.5";
        antigravity = "gemini-3.1-flash-lite-preview";
        opencode = "openai/gpt-5.4-mini";
        codex = "gpt-5.4-mini";
      };
      permission = {
        edit = "ask";
        bash = "ask";
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
        render = key: value: ''"${key}": ${toString value}'';
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
    ${renderOpenCodePermission agent.permission}
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
    in
    {
      inherit (agent) name;
      inherit (agent) description;
      developer_instructions = lib.trim agent.content;
    }
    // lib.optionalAttrs (model != null) {
      inherit model;
    };

  toClaudeMarkdown = lib.mapAttrs (_name: renderClaudeAgent) agents;
  toCopilotMarkdown = lib.mapAttrs (_name: renderCopilotAgent) agents;
  toAntigravityAgents = lib.mapAttrs (_name: agent: {
    prompt = agent.content;
    description = agent.description or "AI agent";
  }) agents;
  toCodexAgents = lib.mapAttrs (_name: renderCodexAgent) agents;
  toOpenCodeMarkdown = lib.mapAttrs (_name: renderOpenCodeAgent) agents;
in
{
  inherit
    agents
    renderClaudeAgent
    renderCopilotAgent
    renderOpenCodeAgent
    toAntigravityAgents
    toClaudeMarkdown
    toCopilotMarkdown
    toCodexAgents
    toOpenCodeMarkdown
    ;
}
