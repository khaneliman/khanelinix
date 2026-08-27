{
  gatewayEnabled ? false,
  lib,
  pkgs ? null,
  ...
}:

let
  modelRouting = import ./model-routing.nix { inherit gatewayEnabled lib; };
  aiAgents = import ./agents.nix {
    inherit gatewayEnabled lib modelRouting;
  };
  codexManagedRequirements = import ./codex-managed-requirements.nix;
  permissions = import ./permissions.nix;

  base = ./base.md;
  claudeContextOverride = builtins.readFile base;
  codexContext = ./codex.md;
  codexContextOverride = lib.concatStringsSep "\n\n" [
    (builtins.readFile base)
    (builtins.readFile codexContext)
  ];
  skillsDir = ./skills;
  skillProjectionScript = ./marketplace/skill_projection.py;
  programOrchestrationDir = ./program-orchestration;
  programOrchestration = {
    canonicalSkill = skillsDir + "/program-orchestration";

    codex.requirements = import (programOrchestrationDir + "/codex/requirements.nix");
  };
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
    codex = {
      hooks = planningWithFilesDir + "/codex/hooks";
      requirements = import (planningWithFilesDir + "/codex/requirements.nix");
    };
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

  technicalWriting = {
    canonicalSkill = skillsDir + "/technical-writing";
    guard = skillsDir + "/technical-writing/scripts/style_guard.py";

    codex.requirements.Stop = [
      {
        hooks = [
          {
            type = "command";
            command = "python3 /etc/codex/hooks/technical-writing/style_guard.py hook codex";
            timeout = 5;
          }
        ];
      }
    ];
  };

  skillRoutingDir = ./skill-routing;
  skillRouting = {
    hook = skillRoutingDir + "/hooks/skill_routing_hook.py";
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

  antigravityTechnicalWritingPlugin =
    if pkgs == null then
      null
    else
      let
        command = "${lib.getExe pkgs.python3} ${technicalWriting.guard} hook antigravity";
        pluginJson = pkgs.writeText "antigravity-technical-writing-plugin.json" (
          builtins.toJSON { name = "technical-writing"; }
        );
        hooksJson = pkgs.writeText "antigravity-technical-writing-hooks.json" (
          builtins.toJSON {
            technical-writing.Stop = [
              {
                type = "command";
                inherit command;
                timeout = 5;
              }
            ];
          }
        );
      in
      pkgs.runCommand "antigravity-technical-writing-plugin" { } ''
        mkdir -p $out
        cp ${pluginJson} $out/plugin.json
        cp ${hooksJson} $out/hooks.json
      '';

  codexHooks =
    lib.zipAttrsWith
      (name: values: if name == "managed_dir" then lib.last values else lib.concatLists values)
      [
        codexManagedRequirements.hooks
        okfMemory.codex.requirements
        planningWithFiles.codex.requirements
        programOrchestration.codex.requirements
        technicalWriting.codex.requirements
      ];
  codexManagedRequirementsWithHooks = codexManagedRequirements // {
    hooks = codexHooks;
  };

  codexHooksDir =
    if pkgs == null then
      null
    else
      pkgs.runCommand "codex-hooks" { } ''
        mkdir -p $out
        cp ${okfMemory.hook} $out/okf_memory_hook.py
        mkdir -p $out/planning-with-files
        cp ${planningWithFiles.codex.hooks}/*.py $out/planning-with-files/
        cp ${planningWithFiles.codex.hooks}/*.sh $out/planning-with-files/
        mkdir -p $out/program-orchestration
        cp ${programOrchestration.canonicalSkill}/scripts/program_context.py $out/program-orchestration/
        cp ${programOrchestration.canonicalSkill}/scripts/program_state.py $out/program-orchestration/
        mkdir -p $out/technical-writing
        cp ${technicalWriting.guard} $out/technical-writing/style_guard.py
      '';

  isSkillDirectory =
    name: type: type == "directory" && builtins.pathExists (skillsDir + "/${name}/SKILL.md");
  allSkills = lib.filterAttrs isSkillDirectory (builtins.readDir skillsDir);
  skills = lib.mapAttrs (name: _: skillsDir + "/${name}") allSkills;

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
      excludeLocal = [
        "mcp-builder"
        "security-toolkit"
      ];
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
      excludeLocal = [
        "mcp-builder"
        "security-toolkit"
      ];
      preferSystem = [
        "skill-creator"
      ];
    };

    opencode = {
      disablePluginSkills = [
        "frontend-ui-ux"
        "git-master"
        "playwright"
        "playwright-cli"
      ];
    };

    piCodingAgent.excludeLocal = [
      "planning-with-files"
    ];

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

  modelHidingProviderForHarness = {
    claudeCode = "claude-code";
    piCodingAgent = "pi";
  };

  projectedSkillsForHarness =
    harnessName:
    let
      source = skillsForHarness harnessName;
      provider = modelHidingProviderForHarness.${harnessName} or null;
    in
    if provider == null then
      source
    else if pkgs == null then
      throw "${harnessName} skill projection requires pkgs"
    else
      pkgs.runCommand "${harnessName}-skill-projection" { } ''
        ${lib.getExe pkgs.python3} ${skillProjectionScript} \
          --provider ${provider} ${source} "$out"
      '';

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

  skillEnabledForHarness =
    harnessName: skillName: builtins.hasAttr skillName (skillsAttrsForHarness harnessName);

  disabledSystemSkillsForHarness = harnessName: (skillPolicyFor harnessName).disableSystem or [ ];

  disabledPluginSkillsForHarness =
    harnessName: (skillPolicyFor harnessName).disablePluginSkills or [ ];
in
{
  inherit
    agents
    base
    claudeContextOverride
    codexContext
    codexContextOverride
    checkedHarnessSkillPolicy
    okfMemory
    modelRouting
    permissions
    planningWithFiles
    programOrchestration
    skillRouting
    skills
    skillsDir
    systemSkillNames
    technicalWriting
    ;

  claudeCode = {
    commands = planningWithFilesCommands;
    agents = aiAgents.toClaudeMarkdown;
    contextOverride = claudeContextOverride;
    okfMemoryEnabled = skillEnabledForHarness "claudeCode" "okf-memory";
    skills = projectedSkillsForHarness "claudeCode";
    inherit skillsDir;
  };

  antigravityCli = {
    okfMemoryPlugin = antigravityOkfMemoryPlugin;
    technicalWritingPlugin = antigravityTechnicalWritingPlugin;
    skills = skillsAttrsForHarness "antigravityCli";
  };

  codex = {
    disabledSystemSkills = disabledSystemSkillsForHarness "codex";
    agents = aiAgents.toCodexAgents;
    contextOverride = codexContextOverride;
    managedRequirements = codexManagedRequirementsWithHooks;
    hooksDir = codexHooksDir;
    okfMemoryEnabled = skillEnabledForHarness "codex" "okf-memory";
    skills = skillsForHarness "codex";
    skillSources = skillsAttrsForHarness "codex";
  };

  githubCopilotCli = {
    agents = aiAgents.toCopilotMarkdown;
    context = base;
    skills = skillsAttrsForHarness "githubCopilotCli";
    inherit base;
  };

  opencode = {
    disabledPluginSkills = disabledPluginSkillsForHarness "opencode";
    skills = skillsForHarness "opencode";
    skillSources = skillsAttrsForHarness "opencode";
    renderAgents = aiAgents.toOpenCodeMarkdown;
  };

  piCodingAgent = {
    skills = projectedSkillsForHarness "piCodingAgent";
  };
}
