{ lib, ... }:
let
  commands = lib.importSubdirs ./commands { };
  aiAgents = import ./agents.nix { inherit lib; };

  agentModels = lib.mapAttrs (_name: agent: agent.model) aiAgents.agents;

  commandAgents = {
    "analyze-git-history" = "explore";
    "code-review" = "debugger";
    "commit-changes" = "refactorer";
    "changelog" = "refactorer";
    "check-todos" = "refactorer";
    "deep-check" = "test-runner";
    "dependency-audit" = "test-runner";
    "git-bisect" = "explore";
    "git-cleanup" = "explore";
    "initialization" = "refactorer";
    "module-lint" = "test-runner";
    "parse-sarif" = "test-runner";
    "resolve-conflicts" = "refactorer";
    "style-audit" = "test-runner";
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

  normalizedCommands = lib.mapAttrs normalizeCommand commands;

  modelValue = provider: model: if builtins.isAttrs model then model.${provider} or null else model;

  renderClaudeFrontmatter =
    command:
    let
      model = modelValue "claude" command.model;
    in
    ''
      ---
      ${lib.optionalString (command.allowedTools != null) "allowed-tools: ${command.allowedTools}"}
      ${lib.optionalString (command.argumentHint != null) "argument-hint: ${command.argumentHint}"}
      ${lib.optionalString (command.description != null) "description: ${command.description}"}
      ${lib.optionalString (model != null) "model: ${model}"}
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

  toClaudeMarkdown = lib.mapAttrs (_name: renderClaudeMarkdown) normalizedCommands;

  toOpenCodeMarkdown = lib.mapAttrs (_name: renderOpenCodeMarkdown) normalizedCommands;

  toGeminiCommands = lib.mapAttrs (_name: command: {
    inherit (command) prompt;
    description = command.description or "AI command";
  }) normalizedCommands;

in
{
  inherit
    normalizedCommands
    toClaudeMarkdown
    toOpenCodeMarkdown
    toGeminiCommands
    ;
}
