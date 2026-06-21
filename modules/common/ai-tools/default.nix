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

  systemSkillNames = {
    claudeCode = [
      "skill-creator"
    ];

    codex = [
      "imagegen"
      "openai-docs"
      "plugin-creator"
      "skill-creator"
      "skill-installer"
    ];
  };

  harnessSkillPolicy = {
    codex = {
      preferSystem = [
        "imagegen"
        "openai-docs"
        "skill-creator"
      ];
      disableSystem = [
        "plugin-creator"
        "skill-installer"
      ];
    };

    claudeCode = {
      preferSystem = [
        "skill-creator"
      ];
    };

    antigravityCli = { };

    githubCopilotCli = { };

    opencode = {
      disablePluginSkills = [
        "frontend-ui-ux"
        "git-master"
        "playwright"
        "playwright-cli"
      ];
    };

    piCodingAgent = { };
  };

  validateSkillPolicy =
    harnessName: policy:
    let
      unknownLocalSkills = builtins.filter (name: !(builtins.hasAttr name allSkills)) (
        policy.excludeLocal or [ ]
      );
      knownSystemSkills = systemSkillNames.${harnessName} or [ ];
      unknownSystemSkills = builtins.filter (name: !(lib.elem name knownSystemSkills)) (
        (policy.preferSystem or [ ]) ++ (policy.disableSystem or [ ])
      );
    in
    if unknownLocalSkills != [ ] then
      throw "Unknown local skills in ${harnessName} policy: ${lib.concatStringsSep ", " unknownLocalSkills}"
    else if unknownSystemSkills != [ ] then
      throw "Unknown system skills in ${harnessName} policy: ${lib.concatStringsSep ", " unknownSystemSkills}"
    else
      policy;

  checkedHarnessSkillPolicy = lib.mapAttrs validateSkillPolicy harnessSkillPolicy;

  skillPolicyFor = harnessName: checkedHarnessSkillPolicy.${harnessName} or { };

  localSkillFilterFor =
    harnessName:
    let
      policy = skillPolicyFor harnessName;
      exclude = lib.unique ((policy.excludeLocal or [ ]) ++ (policy.preferSystem or [ ]));
    in
    {
      hasFilter = exclude != [ ];
      keepNames = builtins.filter (name: !(lib.elem name exclude)) (builtins.attrNames allSkills);
    };

  skillsForHarness =
    harnessName:
    let
      filter = localSkillFilterFor harnessName;
      shouldKeep = name: lib.elem name filter.keepNames;

      shouldKeepPath =
        path:
        let
          relPath = lib.removePrefix (toString skillsDir + "/") (toString path);
          topLevel = if relPath == "" then "" else lib.head (lib.splitString "/" relPath);
        in
        topLevel == "" || shouldKeep topLevel;
    in
    if !filter.hasFilter then
      skillsDir
    else
      builtins.filterSource (path: _: shouldKeepPath path) skillsDir;

  skillsAttrsForHarness =
    harnessName:
    let
      harnessSkills = skillsForHarness harnessName;
      filter = localSkillFilterFor harnessName;
      shouldKeep = name: lib.elem name filter.keepNames;
    in
    lib.mapAttrs (name: _: harnessSkills + "/${name}") (
      lib.filterAttrs (name: _: shouldKeep name) allSkills
    );

  disabledSystemSkillsForHarness = harnessName: (skillPolicyFor harnessName).disableSystem or [ ];

  disabledPluginSkillsForHarness =
    harnessName: (skillPolicyFor harnessName).disablePluginSkills or [ ];
in
{
  inherit
    agents
    base
    commands
    checkedHarnessSkillPolicy
    skills
    skillsDir
    systemSkillNames
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
    disabledSystemSkills = disabledSystemSkillsForHarness "codex";
    skills = skillsForHarness "codex";
  };

  githubCopilotCli = {
    agents = aiAgents.toCopilotMarkdown;
    commandSkills = aiCommands.toCopilotSkills;
    commands = aiCommands.toClaudeMarkdown;
    context = base;
    skills = skillsAttrsForHarness "githubCopilotCli" // aiCommands.toCopilotSkills;
    inherit base;
  };

  opencode = {
    commands = aiCommands.toOpenCodeMarkdown;
    disabledPluginSkills = disabledPluginSkillsForHarness "opencode";
    skills = skillsForHarness "opencode";
    inherit agents;
    renderAgents = aiAgents.toOpenCodeMarkdown;
  };

  piCodingAgent = {
    skills = skillsForHarness "piCodingAgent";
  };

  mergeCommands = existingCommands: newCommands: existingCommands // newCommands;
}
