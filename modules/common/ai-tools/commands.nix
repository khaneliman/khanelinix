{ lib, ... }:
let
  commands = lib.importSubdirs ./commands { };
  aiAgents = import ./agents.nix { inherit lib; };

  agentModels = lib.mapAttrs (_name: agent: agent.model) aiAgents.agents;

  commandAgents = {
    "explain-code" = "explore";
    "extract-interface" = "explore";
    "find-usages" = "explore";
    "summarize-module" = "explore";
    "refactor-suggest" = "refactorer";
    "generate-docs" = "doc-writer";
    "generate-tests" = "test-runner";

    "commit-changes" = "code-reviewer";
    "git-history" = "code-reviewer";
    "git-resolve" = "code-reviewer";
    "git-bisect" = "code-reviewer";
    "git-cleanup" = "code-reviewer";

    "code-review" = "code-reviewer";
    "deep-check" = "code-reviewer";
    "dependency-audit" = "code-reviewer";
    "module-lint" = "code-reviewer";
    "style-audit" = "code-reviewer";
    "check-todos" = "code-reviewer";
    "parse-sarif" = "code-reviewer";

    "flake-update" = "nix-builder";
    "module-scaffold" = "nix-builder";
    "option-migrate" = "nix-builder";
    "nix-refactor" = "nix-builder";
    "template-new" = "nix-builder";

    "changelog" = "doc-writer";
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
