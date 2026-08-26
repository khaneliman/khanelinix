{
  gatewayEnabled ? false,
  lib,
  modelRouting ? import ./model-routing.nix { inherit gatewayEnabled lib; },
  ...
}:
let
  agentsBasePath = ./agents;
  modelValue = provider: model: if builtins.isAttrs model then model.${provider} or null else model;
  controlCharacters = lib.stringToCharacters (
    builtins.fromJSON ''"\u0001\u0002\u0003\u0004\u0005\u0006\u0007\u0008\u0009\u000a\u000b\u000c\u000d\u000e\u000f\u0010\u0011\u0012\u0013\u0014\u0015\u0016\u0017\u0018\u0019\u001a\u001b\u001c\u001d\u001e\u001f\u007f"''
  );
  requireSafeText =
    context: value:
    if
      builtins.isString value && !(lib.any (character: lib.hasInfix character value) controlCharacters)
    then
      value
    else
      throw "${context} must be text without control characters";
  renderYamlString = context: value: builtins.toJSON (requireSafeText context value);
  renderYamlScalar =
    context: value:
    if builtins.isString value then renderYamlString context value else builtins.toJSON value;

  readOnlyTools = [
    "Read"
    "Bash"
    "Grep"
    "Glob"
  ];
  writeTools = readOnlyTools ++ [
    "Edit"
    "Write"
  ];

  lunaDiscoveryAgent = role: {
    tools = readOnlyTools;
    model = modelRouting.modelsForRole role;
    model_reasoning_effort = modelRouting.reasoningEffortForRole role;
    sandbox_mode.codex = "read-only";
    content = builtins.readFile (agentsBasePath + "/general/fact-finder.md");
  };

  implementationAgent = role: {
    tools = writeTools;
    model = modelRouting.modelsForRole role;
    model_reasoning_effort = modelRouting.reasoningEffortForRole role;
    sandbox_mode.codex = "workspace-write";
    content = builtins.readFile (agentsBasePath + "/general/implementer.md");
  };

  mkGatewayAgent =
    {
      alias,
      description,
      name,
      reasoningEffort ? null,
      workspaceWrite ? write,
      write ? false,
    }:
    {
      inherit name;
      description = "Explicit model route. Use only after user model/provider intent or a multi-provider-sdlc route. ${description}";
      projection = "gateway";
      providers = [
        "claudeCode"
        "codex"
        "opencode"
      ];
      tools = if write then writeTools else readOnlyTools;
      model = {
        claude = alias;
        codex = alias;
        opencode = "cliproxyapi/${alias}";
      };
      model_provider.codex = "cliproxyapi";
      model_reasoning_effort.codex = reasoningEffort;
      sandbox_mode.codex = if workspaceWrite then "workspace-write" else "read-only";
      content = builtins.readFile (agentsBasePath + "/general/model-worker.md");
    };

  semanticAgents = lib.mapAttrs (_name: agent: agent // { projection = "native"; }) {
    mechanic = {
      name = "mechanic";
      description = "Latency-first worker for one obvious low-risk lookup, mechanical one-file edit, or focused check.";
      tools = [
        "Read"
        "Edit"
        "Write"
        "Bash"
        "Grep"
        "Glob"
      ];
      model = modelRouting.modelsForRole "mechanic";
      model_reasoning_effort = modelRouting.reasoningEffortForRole "mechanic";
      sandbox_mode.codex = "workspace-write";
      content = builtins.readFile (agentsBasePath + "/general/mechanic.md");
    };
    "fact-finder" = lunaDiscoveryAgent "fact-finder" // {
      name = "fact-finder";
      description = "Read-only fact-finding specialist for scoped repo questions. Use for multi-file discovery, caller tracing, config lookup, pattern comparison, and bounded evidence gathering when main context should stay small.";
    };
    explorer = lunaDiscoveryAgent "explorer" // {
      name = "explorer";
      description = "Read-heavy explorer for repository search, caller tracing, config lookup, and bounded evidence gathering.";
    };
    checker = {
      name = "checker";
      description = "Focused validation specialist for one bounded test, lint, evaluation, or build command with a known success condition.";
      tools = readOnlyTools;
      model = modelRouting.modelsForRole "checker";
      model_reasoning_effort = modelRouting.reasoningEffortForRole "checker";
      sandbox_mode.codex = "workspace-write";
      content = builtins.readFile (agentsBasePath + "/general/checker.md");
    };
    "probe-runner" = {
      name = "probe-runner";
      description = "Bounded probe and reproduction specialist. Use for one-shot commands, non-destructive checks, reproduction attempts, browser probes, eval/build probes, and noisy output summaries.";
      tools = [
        "Read"
        "Bash"
        "Grep"
        "Glob"
      ];
      model = modelRouting.modelsForRole "probe-runner";
      model_reasoning_effort = modelRouting.reasoningEffortForRole "probe-runner";
      sandbox_mode = {
        codex = "workspace-write";
      };
      content = builtins.readFile (agentsBasePath + "/general/probe-runner.md");
    };
    debugger = {
      name = "debugger";
      description = "Read-only root-cause specialist for a reproduced error, exception, test failure, or unexpected behavior with supplied symptom or evidence.";
      tools = [
        "Read"
        "Bash"
        "Grep"
        "Glob"
      ];
      model = modelRouting.modelsForRole "debugger";
      model_reasoning_effort = modelRouting.reasoningEffortForRole "debugger";
      sandbox_mode = {
        codex = "read-only";
      };
      content = builtins.readFile (agentsBasePath + "/general/debugger.md");
    };
    test-runner = {
      name = "test-runner";
      description = "Test execution specialist for broad or noisy suites, lint, build validation, failure analysis, and post-change verification.";
      tools = [
        "Read"
        "Bash"
        "Grep"
        "Glob"
      ];
      model = modelRouting.modelsForRole "test-runner";
      model_reasoning_effort = modelRouting.reasoningEffortForRole "test-runner";
      sandbox_mode = {
        codex = "workspace-write";
      };
      content = builtins.readFile (agentsBasePath + "/general/test-runner.md");
    };
    reviewer = {
      name = "reviewer";
      description = "Fresh read-only reviewer for scoped plans or current diffs, ranked actionable findings, and residual-risk assessment.";
      tools = [
        "Read"
        "Bash"
        "Grep"
        "Glob"
      ];
      model = modelRouting.modelsForRole "reviewer";
      model_reasoning_effort = modelRouting.reasoningEffortForRole "reviewer";
      sandbox_mode.codex = "read-only";
      content = builtins.readFile (agentsBasePath + "/general/reviewer.md");
    };
    implementer = implementationAgent "implementer" // {
      name = "implementer";
      description = "Bounded implementation specialist for one parent-scoped change or correction batch with focused validation.";
    };
    worker = implementationAgent "worker" // {
      name = "worker";
      description = "Execution worker for one bounded implementation or fix batch with focused validation.";
    };
  };

  gatewayAgents = lib.mapAttrs (_name: mkGatewayAgent) modelRouting.gatewayAgentSpecs;

  agents = semanticAgents // gatewayAgents;

  agentsForProvider =
    provider:
    lib.filterAttrs (
      _name: agent:
      let
        # Gateway-capable harnesses need semantic roles for automatic routing
        # and model-named agents for explicit provider selection. Copilot has
        # no gateway model-agent projection.
        expectedProjections =
          if provider == "githubCopilotCli" || !gatewayEnabled then
            [ "native" ]
          else
            [
              "native"
              "gateway"
            ];
      in
      lib.elem agent.projection expectedProjections && lib.elem provider (agent.providers or [ provider ])
    ) agents;

  renderClaudeFrontmatter =
    agent:
    let
      description = agent.claudeDescription or agent.description;
      model = agent.model.claude or agent.model;
      tools = renderYamlString "Claude tool IDs" (lib.concatStringsSep ", " agent.tools);
    in
    ''
      ---
      name: ${renderYamlString "Claude agent name" agent.name}
      description: ${renderYamlString "Claude agent description" description}
      tools: ${tools}
      model: ${renderYamlString "Claude model ID" model}
      ---
    '';

  renderClaudeAgent = agent: ''
    ${lib.trim (renderClaudeFrontmatter agent)}

    ${lib.trim agent.content}
  '';

  renderOpenCodeTools =
    agent:
    let
      allowed = map lib.toLower agent.tools;
      isAllowed = tool: lib.elem tool allowed;
      coreTools = [
        "bash"
        "edit"
        "write"
      ];
      coreToolLines = map (
        tool: "  ${renderYamlString "OpenCode tool ID" tool}: ${builtins.toJSON (isAllowed tool)}"
      ) coreTools;
    in
    lib.concatStringsSep "\n" coreToolLines;

  renderOpenCodePermission =
    permission:
    if permission == null then
      ""
    else
      let
        render =
          key: value:
          "  ${renderYamlString "OpenCode permission ID" key}: ${renderYamlScalar "OpenCode permission value" value}";
      in
      ''
        permission:
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList render permission)}
      '';

  renderOpenCodeFrontmatter =
    agent:
    let
      mode = agent.mode or "all";
      model = agent.model.opencode or agent.model;
    in
    ''
      ---
      description: ${renderYamlString "OpenCode agent description" agent.description}
      mode: ${renderYamlString "OpenCode agent mode" mode}
      model: ${renderYamlString "OpenCode model ID" model}

      tools:
      ${renderOpenCodeTools agent}
      ${renderOpenCodePermission (agent.permission or null)}
      ---
    '';

  renderOpenCodeAgent = agent: ''
    ${lib.trim (renderOpenCodeFrontmatter agent)}

    ${lib.trim agent.content}
  '';

  renderCopilotFrontmatter =
    agent:
    let
      model = if builtins.isAttrs agent.model then agent.model.copilot or null else agent.model;
    in
    ''
      ---
      name: ${renderYamlString "Copilot agent name" agent.name}
      description: ${renderYamlString "Copilot agent description" agent.description}
      ${lib.optionalString (model != null) "model: ${renderYamlString "Copilot model ID" model}"}
      ---
    '';

  renderCopilotAgent = agent: ''
    ${lib.trim (renderCopilotFrontmatter agent)}

    ${lib.trim agent.content}
  '';

  renderCodexAgent =
    agent:
    let
      model = modelValue "codex" agent.model;
      modelReasoningEffort = modelValue "codex" (agent.model_reasoning_effort or null);
      modelProvider = modelValue "codex" (agent.model_provider or null);
      sandboxMode = modelValue "codex" (agent.sandbox_mode or null);
    in
    {
      name = requireSafeText "Codex agent name" agent.name;
      description = requireSafeText "Codex agent description" agent.description;
      developer_instructions = lib.trim agent.content;
    }
    // lib.optionalAttrs (model != null) {
      model = requireSafeText "Codex model ID" model;
    }
    // lib.optionalAttrs (modelReasoningEffort != null) {
      model_reasoning_effort = requireSafeText "Codex reasoning effort" modelReasoningEffort;
    }
    // lib.optionalAttrs (modelProvider != null) {
      model_provider = requireSafeText "Codex provider ID" modelProvider;
    }
    // lib.optionalAttrs (sandboxMode != null) {
      sandbox_mode = requireSafeText "Codex sandbox mode" sandboxMode;
    }
    // lib.optionalAttrs (agent ? nickname_candidates) {
      nickname_candidates = map (requireSafeText "Codex nickname candidate") agent.nickname_candidates;
    };

  toClaudeMarkdown = lib.mapAttrs (_name: renderClaudeAgent) (agentsForProvider "claudeCode");
  toCopilotMarkdown = lib.mapAttrs (_name: renderCopilotAgent) (agentsForProvider "githubCopilotCli");
  toCodexAgents = lib.mapAttrs (_name: renderCodexAgent) (agentsForProvider "codex");
  toOpenCodeMarkdown = lib.mapAttrs (_name: renderOpenCodeAgent) (agentsForProvider "opencode");
in
{
  inherit
    agents
    agentsForProvider
    renderClaudeAgent
    renderCopilotAgent
    renderOpenCodeAgent
    toClaudeMarkdown
    toCopilotMarkdown
    toCodexAgents
    toOpenCodeMarkdown
    ;
}
