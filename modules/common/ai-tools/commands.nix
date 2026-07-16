{ lib, ... }:
let
  importedCommands = lib.importSubdirs ./commands { };
  aiAgents = import ./agents.nix { inherit lib; };

  agentModelDefaults = {
    build = {
      claude = "sonnet";
      opencode = "openai/gpt-5.6-terra";
    };
    explore = {
      claude = "haiku";
      copilot = "claude-haiku-4.5";
      opencode = "openai/gpt-5.6-luna";
    };
  };

  agentModels = agentModelDefaults // lib.mapAttrs (_name: agent: agent.model) aiAgents.agents;

  commandAgents = {
    changelog = "build";
    check-todos = "test-runner";
    dependency-audit = "test-runner";
  };

  normalizeCommand =
    name: command:
    let
      agent = command.agent or (commandAgents.${name} or "explore");
      model = command.model or (agentModels.${agent} or { });
    in
    {
      commandName = command.commandName or name;
      description = command.description or null;
      allowedTools = command.allowedTools or null;
      argumentHint = command.argumentHint or null;
      prompt = command.prompt or "";
      inherit agent model;
      subtask = command.subtask or false;
    };

  commands = lib.mapAttrs normalizeCommand importedCommands;

  modelValue = provider: model: if builtins.isAttrs model then model.${provider} or null else model;

  renderClaudeFrontmatter =
    command:
    let
      model = modelValue "claude" command.model;
    in
    ''
      ---
      ${lib.optionalString (
        command.allowedTools != null
      ) "allowed-tools: ${builtins.toJSON command.allowedTools}"}
      ${lib.optionalString (
        command.argumentHint != null
      ) "argument-hint: ${builtins.toJSON command.argumentHint}"}
      ${lib.optionalString (
        command.description != null
      ) "description: ${builtins.toJSON command.description}"}
      ${lib.optionalString (model != null) "model: ${builtins.toJSON model}"}
      ---
    '';

  renderClaudeMarkdown = command: ''
    ${lib.trim (renderClaudeFrontmatter command)}

    ${lib.trim command.prompt}
  '';

  renderOpenCodeFrontmatter =
    command:
    let
      model = modelValue "opencode" command.model;
    in
    ''
      ---
      ${lib.optionalString (command.description != null) "description: ${command.description}"}
      ${lib.optionalString (command.agent != null) "agent: ${command.agent}"}
      ${lib.optionalString (model != null) "model: ${model}"}
      ${lib.optionalString (command.subtask or false) "subtask: true"}
      ---
    '';

  renderOpenCodeMarkdown = command: ''
    ${lib.trim (renderOpenCodeFrontmatter command)}

    ${lib.trim command.prompt}
  '';

  renderCopilotSkill = command: ''
    ---
    name: ${builtins.toJSON command.commandName}
    description: ${builtins.toJSON (command.description or "AI command")}
    ---

    ${lib.trim command.prompt}
  '';

  renderCodexSkill = command: ''
    ---
    name: ${builtins.toJSON command.commandName}
    description: ${builtins.toJSON (command.description or "AI command")}
    ---

    ${lib.trim command.prompt}
  '';

  renderCodexSkillMetadata = _command: ''
    policy:
      allow_implicit_invocation: false
  '';

  renderCodexSkillFiles = command: {
    "SKILL.md" = renderCodexSkill command;
    "agents/openai.yaml" = renderCodexSkillMetadata command;
  };

  toClaudeMarkdown = lib.mapAttrs (_name: renderClaudeMarkdown) commands;

  toCopilotSkills = lib.mapAttrs (_name: renderCopilotSkill) commands;

  toCodexSkills = lib.mapAttrs (_name: renderCodexSkill) commands;

  toCodexSkillFiles = lib.mapAttrs (_name: renderCodexSkillFiles) commands;

  toOpenCodeMarkdown = lib.mapAttrs (_name: renderOpenCodeMarkdown) commands;

  toAntigravityCommands = lib.mapAttrs (_name: command: {
    inherit (command) prompt;
    description = command.description or "AI command";
  }) commands;
in
{
  inherit
    commands
    renderClaudeMarkdown
    renderCopilotSkill
    renderCodexSkill
    renderCodexSkillFiles
    renderCodexSkillMetadata
    renderOpenCodeMarkdown
    toAntigravityCommands
    toClaudeMarkdown
    toCopilotSkills
    toCodexSkills
    toCodexSkillFiles
    toOpenCodeMarkdown
    ;

  normalizedCommands = commands;
}
