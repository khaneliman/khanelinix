{ lib, ... }:

let
  aiCommands = import ./commands.nix { inherit lib; };
  aiAgents = import ./agents.nix { inherit lib; };

  base = ./base.md;
  skillsDir = ./skills;
  skills = lib.mapAttrs (name: _: skillsDir + "/${name}") (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir skillsDir)
  );

  inherit (aiCommands) commands;
  inherit (aiAgents) agents;
in
{
  inherit
    agents
    base
    commands
    skills
    skillsDir
    ;

  claudeCode = {
    commands = aiCommands.toClaudeMarkdown;
    agents = aiAgents.toClaudeMarkdown;
    inherit skillsDir;
  };

  geminiCli = {
    commands = aiCommands.toGeminiCommands;
    agents = aiAgents.toGeminiAgents;
    inherit skills;
  };

  codex = {
    inherit skillsDir;
  };

  opencode = {
    commands = aiCommands.toOpenCodeMarkdown;
    inherit agents;
    renderAgents = aiAgents.toOpenCodeMarkdown;
  };

  mergeCommands = existingCommands: newCommands: existingCommands // newCommands;
}
