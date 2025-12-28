{ lib, ... }:

let
  aiCommands = import ./commands.nix { inherit lib; };
  aiAgents = import ./agents.nix { inherit lib; };

  # Extract description from agent frontmatter
  extractDescription =
    agentText:
    let
      parts = lib.splitString "---" agentText;
      frontmatter = if lib.length parts >= 2 then lib.elemAt parts 1 else "";
      descMatch = lib.optionals (lib.hasInfix "description:" frontmatter) [
        (lib.removePrefix "description: " (
          lib.trim (
            lib.head (lib.filter (line: lib.hasPrefix "description:" line) (lib.splitString "\n" frontmatter))
          )
        ))
      ];
    in
    if descMatch != [ ] then lib.head descMatch else null;

  # Extract prompt content from agent
  extractPrompt =
    agentText:
    let
      parts = lib.splitString "---" agentText;
      mainContent = if lib.length parts >= 3 then lib.elemAt parts 2 else agentText;
    in
    lib.trim mainContent;

  convertCommandsToGemini =
    commands:
    lib.mapAttrs (name: prompt: {
      inherit prompt;
      description =
        let
          lines = lib.splitString "\n" prompt;
          descLine = lib.findFirst (line: lib.hasPrefix "description:" line) "" lines;
        in
        if descLine != "" then
          lib.removePrefix "description: " (lib.trim descLine)
        else
          "AI command: ${name}";
    }) commands;

  convertAgentsToGemini =
    agents:
    lib.mapAttrs (
      name: agentText:
      let
        description = extractDescription agentText;
        prompt = extractPrompt agentText;
      in
      {
        inherit prompt;
        description = if description != null then description else "AI agent: ${name}";
      }
    ) agents;

in
{
  claudeCode = {
    commands = aiCommands;
    agents = aiAgents;
  };

  geminiCli = {
    commands = convertCommandsToGemini aiCommands;
    agents = convertAgentsToGemini aiAgents;
  };

  opencode = {
    commands = aiCommands;
    agents = aiAgents;
    # Export helper functions for OpenCode module to use
    inherit extractDescription extractPrompt;
  };

  mergeCommands = existingCommands: newCommands: existingCommands // newCommands;
}
