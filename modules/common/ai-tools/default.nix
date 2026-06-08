{ lib, ... }:

let
  aiCommands = import ./commands.nix { inherit lib; };
  aiAgents = import ./agents.nix { inherit lib; };

  base = ./base.md;
  skillsDir = ./skills;

  isSkillDirectory =
    name: type: type == "directory" && builtins.pathExists (skillsDir + "/${name}/SKILL.md");
  allSkills = lib.filterAttrs isSkillDirectory (builtins.readDir skillsDir);
  skills = lib.mapAttrs (name: _: skillsDir + "/${name}") allSkills;

  inherit (aiCommands) commands;
  inherit (aiAgents) agents;

  harnessSkillFilters = {
    codex = {
      exclude = [
        "skill-creator"
      ];
    };

    claudeCode = {
      exclude = [
        "skill-creator"
      ];
    };
  };

  skillsForHarness =
    harnessName:
    let
      exclude = (harnessSkillFilters.${harnessName} or { }).exclude or [ ];
      shouldKeep = name: !(lib.elem name exclude);

      shouldKeepPath =
        path:
        let
          relPath = lib.removePrefix (toString skillsDir + "/") (toString path);
          topLevel = if relPath == "" then "" else lib.head (lib.splitString "/" relPath);
        in
        topLevel == "" || shouldKeep topLevel;
    in
    if exclude == [ ] then
      skillsDir
    else
      builtins.filterSource (path: _: shouldKeepPath path) skillsDir;

  skillsAttrsForHarness =
    harnessName:
    let
      harnessSkills = skillsForHarness harnessName;
      exclude = (harnessSkillFilters.${harnessName} or { }).exclude or [ ];
      shouldKeep = name: !(lib.elem name exclude);
    in
    lib.mapAttrs (name: _: harnessSkills + "/${name}") (
      lib.filterAttrs (name: _: shouldKeep name) allSkills
    );
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
    skills = skillsForHarness "claudeCode";
    inherit skillsDir;
  };

  antigravityCli = {
    commands = aiCommands.toAntigravityCommands;
    agents = aiAgents.toAntigravityAgents;
    skills = skillsForHarness "antigravityCli";
  };

  codex = {
    skills = skillsForHarness "codex";
  };

  githubCopilotCli = {
    agents = aiAgents.toCopilotMarkdown;
    commandSkills = aiCommands.toCopilotSkills;
    context = base;
    skills = skillsAttrsForHarness "githubCopilotCli" // aiCommands.toCopilotSkills;
    inherit base;
  };

  opencode = {
    commands = aiCommands.toOpenCodeMarkdown;
    skills = skillsForHarness "opencode";
    inherit agents;
    renderAgents = aiAgents.toOpenCodeMarkdown;
  };

  piCodingAgent = {
    skills = skillsForHarness "piCodingAgent";
  };

  mergeCommands = existingCommands: newCommands: existingCommands // newCommands;
}
