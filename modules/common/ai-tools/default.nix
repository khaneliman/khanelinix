{ lib, ... }:

let
  inherit (lib) mapAttrs;

  aiCommands = import ./commands.nix { inherit lib; };
  aiAgents = import ./agents.nix { inherit lib; };

  convertCommandsToGemini =
    commands:
    mapAttrs (name: prompt: {
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
    mapAttrs (
      name: agentText:
      let
        parts = lib.splitString "---" agentText;
        mainContent = if lib.length parts >= 3 then lib.elemAt parts 2 else agentText;
        frontmatter = if lib.length parts >= 2 then lib.elemAt parts 1 else "";
        descMatch = lib.optionals (lib.hasInfix "description:" frontmatter) [
          (lib.removePrefix "description: " (
            lib.trim (
              lib.head (lib.filter (line: lib.hasPrefix "description:" line) (lib.splitString "\n" frontmatter))
            )
          ))
        ];
        description = if descMatch != [ ] then lib.head descMatch else "AI agent: ${name}";
      in
      {
        prompt = lib.trim mainContent;
        inherit description;
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

  mergeCommands = existingCommands: newCommands: existingCommands // newCommands;
}
