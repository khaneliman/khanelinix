{ lib, ... }:

let
  inherit (lib)
    filterAttrs
    mapAttrs
    ;

  aiCommands = import ./commands.nix { inherit lib; };
  aiAgents = import ./agents.nix { inherit lib; };
  base = ./base.md;
  skillsDir = ./skills;
  skills = mapAttrs (name: _: skillsDir + "/${name}") (
    filterAttrs (_: type: type == "directory") (builtins.readDir skillsDir)
  );

  convertAgentsToGemini =
    agents:
    mapAttrs (name: agent: {
      prompt = agent.content;
      description = agent.description or "AI agent: ${name}";
    }) agents;

  # .agents specification support
  renderMode = _name: agent: ''
    ---
    id: ${agent.name}
    title: ${agent.name}
    description: ${agent.description}
    x.model:
      claude: ${agent.model.claude or agent.model}
      gemini: ${agent.model.gemini or agent.model}
      opencode: ${agent.model.opencode or agent.model}
    ---

    ${lib.trim agent.content}
  '';

  renderSnippet = _name: command: ''
    ---
    description: ${command.description or "AI command"}
    ${lib.optionalString (command.allowedTools != null) "x.allowed-tools: ${command.allowedTools}"}
    ${lib.optionalString (command.argumentHint != null) "x.argument-hint: ${command.argumentHint}"}
    ---

    ${lib.trim command.prompt}
  '';

  agentsConfig = {
    manifest = {
      specVersion = "1.0.0";
      defaults = {
        mode = "explore";
        policy = "default";
      };
      enabled = {
        modes = builtins.attrNames aiAgents.agents;
        skills = builtins.attrNames skills;
      };
    };
    prompts = {
      base = builtins.readFile base;
      snippets = mapAttrs renderSnippet aiCommands.normalizedCommands;
    };
    modes = mapAttrs renderMode aiAgents.agents;
    inherit skillsDir;
  };

in
{
  claudeCode = {
    commands = aiCommands.toClaudeMarkdown;
    agents = aiAgents.toClaudeMarkdown;
    inherit skillsDir;
  };

  geminiCli = {
    commands = aiCommands.toGeminiCommands;
    agents = convertAgentsToGemini aiAgents.agents;
    inherit skills;
  };

  codex = {
    inherit skillsDir;
  };

  opencode = {
    commands = aiCommands.toOpenCodeMarkdown;
    inherit (aiAgents) agents;
    renderAgents = aiAgents.toOpenCodeMarkdown;
  };

  inherit
    base
    skills
    skillsDir
    agentsConfig
    ;

  mergeCommands = existingCommands: newCommands: existingCommands // newCommands;
}
