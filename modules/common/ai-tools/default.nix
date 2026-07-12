{
  lib,
  pkgs ? null,
  ...
}:

let
  aiCommands = import ./commands.nix { inherit lib; };
  aiAgents = import ./agents.nix { inherit lib; };
  codexManagedRequirements = import ./codex-managed-requirements.nix;
  permissions = import ./permissions.nix;

  base = ./base.md;
  codexContext = ./codex.md;
  codexContextOverride = lib.concatStringsSep "\n\n" [
    (builtins.readFile base)
    (builtins.readFile codexContext)
  ];
  skillsDir = ./skills;
  planningWithFilesDir = ./planning-with-files;
  planningWithFilesCommandsDir = planningWithFilesDir + "/commands";
  planningWithFilesCommandNames = [
    "plan"
    "plan-attest"
    "plan-goal"
    "plan-loop"
    "pwf"
    "status"
  ];
  planningWithFilesCommands = builtins.listToAttrs (
    map (name: {
      inherit name;
      value = planningWithFilesCommandsDir + "/${name}.md";
    }) planningWithFilesCommandNames
  );
  planningWithFiles = {
    commands = planningWithFilesCommands;
    canonicalSkill = skillsDir + "/planning-with-files";

    antigravityCli.skill = planningWithFilesDir + "/gemini/skills/planning-with-files";

    codex = {
      hooks = planningWithFilesDir + "/codex";
      skill = planningWithFilesDir + "/codex/skills/planning-with-files";
    };

    opencode.skill = planningWithFilesDir + "/opencode/skills/planning-with-files";

    piCodingAgent.package = planningWithFilesDir + "/pi/skills/planning-with-files";
  };

  okfMemoryDir = ./okf-memory;
  okfMemory = {
    canonicalSkill = skillsDir + "/okf-memory";
    hook = okfMemoryDir + "/hooks/okf_memory_hook.py";

    codex = {
      requirements = import (okfMemoryDir + "/codex/requirements.nix");
    };
  };

  antigravityOkfMemoryPlugin =
    if pkgs == null then
      null
    else
      let
        command = event: "${lib.getExe pkgs.python3} ${okfMemory.hook} antigravity ${event}";
        pluginJson = pkgs.writeText "antigravity-okf-memory-plugin.json" (
          builtins.toJSON { name = "okf-memory"; }
        );
        hooksJson = pkgs.writeText "antigravity-okf-memory-hooks.json" (
          builtins.toJSON {
            okf-memory = {
              PreInvocation = [
                {
                  type = "command";
                  command = command "pre-invocation";
                  timeout = 5;
                }
              ];
              PostToolUse = [
                {
                  matcher = "*";
                  hooks = [
                    {
                      type = "command";
                      command = command "post-tool";
                      timeout = 5;
                    }
                  ];
                }
              ];
              Stop = [
                {
                  type = "command";
                  command = command "stop";
                  timeout = 5;
                }
              ];
            };
          }
        );
      in
      pkgs.runCommand "antigravity-okf-memory-plugin" { } ''
        mkdir -p $out
        cp ${pluginJson} $out/plugin.json
        cp ${hooksJson} $out/hooks.json
      '';

  # Merge okf-memory's SessionStart hook into planning-with-files' managed
  # requirements. Event values are lists, so entries append rather than
  # replace. `managed_dir` isn't an event key and passes through untouched.
  mergeHookEvents =
    a: b:
    let
      isEventKey = name: name != "managed_dir";
      eventNames = lib.unique (
        (builtins.filter isEventKey (builtins.attrNames a)) ++ (builtins.attrNames b)
      );
    in
    (lib.filterAttrs (name: _: !(isEventKey name)) a)
    // lib.genAttrs eventNames (name: (a.${name} or [ ]) ++ (b.${name} or [ ]));

  codexManagedRequirementsMerged = codexManagedRequirements // {
    hooks = mergeHookEvents codexManagedRequirements.hooks okfMemory.codex.requirements;
  };

  # Combine planning-with-files' and okf-memory's Codex hook scripts into one
  # directory, since both are deployed to the same /etc/codex/hooks path.
  # Falls back to planning-with-files' own directory when pkgs isn't passed
  # (some callers of this module don't need Codex support and omit it).
  codexHooksDirMerged =
    if pkgs == null then
      planningWithFiles.codex.hooks + "/hooks"
    else
      pkgs.runCommand "codex-hooks-merged" { } ''
        mkdir -p $out
        cp -R ${planningWithFiles.codex.hooks}/hooks/. $out/
        cp ${okfMemory.hook} $out/okf_memory_hook.py
      '';

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
    codexContext
    codexContextOverride
    checkedHarnessSkillPolicy
    okfMemory
    permissions
    planningWithFiles
    skills
    skillsDir
    systemSkillNames
    ;

  claudeCode = {
    commands = aiCommands.toClaudeMarkdown // planningWithFilesCommands;
    agents = aiAgents.toClaudeMarkdown;
    skills = skillsForHarness "claudeCode";
    inherit skillsDir;
  };

  antigravityCli = {
    commands = aiCommands.toAntigravityCommands;
    okfMemoryPlugin = antigravityOkfMemoryPlugin;
    skills = skillsAttrsForHarness "antigravityCli";
  };

  codex = {
    disabledSystemSkills = disabledSystemSkillsForHarness "codex";
    agents = removeAttrs aiAgents.toCodexAgents [ "refactorer" ];
    commandSkillFiles = aiCommands.toCodexSkillFiles;
    contextOverride = codexContextOverride;
    managedRequirements = codexManagedRequirementsMerged;
    hooksDir = codexHooksDirMerged;
    skills = skillsForHarness "codex";
    skillSources = skillsAttrsForHarness "codex" // {
      planning-with-files = planningWithFiles.codex.skill;
    };
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
    skillSources = skillsAttrsForHarness "opencode" // {
      planning-with-files = planningWithFiles.opencode.skill;
    };
    inherit agents;
    renderAgents = aiAgents.toOpenCodeMarkdown;
  };

  piCodingAgent = {
    skills = skillsForHarness "piCodingAgent";
  };

  mergeCommands = existingCommands: newCommands: existingCommands // newCommands;
}
