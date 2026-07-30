{
  gatewayEnabled ? false,
  lib,
  ...
}:
let
  agentsBasePath = ./agents;
  modelValue = provider: model: if builtins.isAttrs model then model.${provider} or null else model;
  routedModel =
    gatewayModels: native:
    let
      gatewayModel =
        provider: if builtins.isAttrs gatewayModels then gatewayModels.${provider} else gatewayModels;
    in
    native
    // lib.optionalAttrs gatewayEnabled {
      claude = gatewayModel "claude";
      codex = gatewayModel "codex";
      opencode = "cliproxyapi/${gatewayModel "opencode"}";
    };
  routedProvider.codex = if gatewayEnabled then "cliproxyapi" else null;

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

  lunaDiscoveryAgent = {
    tools = readOnlyTools;
    model = routedModel "claude-gpt-5.6-luna" {
      claude = "haiku";
      copilot = "claude-haiku-4.5";
      opencode = "openai/gpt-5.6-luna";
      codex = "gpt-5.6-luna";
    };
    model_provider = routedProvider;
    model_reasoning_effort.codex = "medium";
    sandbox_mode.codex = "read-only";
    content = builtins.readFile (agentsBasePath + "/general/fact-finder.md");
  };

  implementationAgent = {
    tools = writeTools;
    model =
      routedModel
        {
          claude = "claude-opus-5";
          codex = "claude-gpt-5.6-luna";
          opencode = "claude-gpt-5.6-luna";
        }
        {
          claude = "opus";
          copilot = "claude-opus-4.6";
          opencode = "openai/gpt-5.6-luna";
          codex = "gpt-5.6-luna";
        };
    model_provider = routedProvider;
    model_reasoning_effort.codex = "medium";
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
      inherit description name;
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
      model = routedModel "claude-gpt-5.3-codex-spark" {
        claude = "haiku";
        copilot = "claude-haiku-4.5";
        opencode = "openai/gpt-5.3-codex-spark";
        codex = "gpt-5.3-codex-spark";
      };
      model_provider = routedProvider;
      model_reasoning_effort.codex = "medium";
      sandbox_mode.codex = "workspace-write";
      content = builtins.readFile (agentsBasePath + "/general/mechanic.md");
    };
    "fact-finder" = lunaDiscoveryAgent // {
      name = "fact-finder";
      description = "Read-only fact-finding specialist for scoped repo questions. Use for multi-file discovery, caller tracing, config lookup, pattern comparison, and bounded evidence gathering when main context should stay small.";
    };
    explorer = lunaDiscoveryAgent // {
      name = "explorer";
      description = "Read-heavy explorer for repository search, caller tracing, config lookup, and bounded evidence gathering.";
    };
    checker = {
      name = "checker";
      description = "Focused validation specialist for one bounded test, lint, evaluation, or build command with a known success condition.";
      tools = readOnlyTools;
      model = routedModel "claude-gpt-5.3-codex-spark" {
        claude = "haiku";
        copilot = "claude-haiku-4.5";
        opencode = "openai/gpt-5.3-codex-spark";
        codex = "gpt-5.3-codex-spark";
      };
      model_provider = routedProvider;
      model_reasoning_effort.codex = "medium";
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
      model = routedModel "claude-gpt-5.6-luna" {
        claude = "haiku";
        copilot = "claude-haiku-4.5";
        opencode = "openai/gpt-5.6-luna";
        codex = "gpt-5.6-luna";
      };
      model_provider = routedProvider;
      model_reasoning_effort = {
        codex = "medium";
      };
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
      model =
        routedModel
          {
            claude = "claude-gemini-3.1-pro";
            codex = "claude-gpt-5.6-sol";
            opencode = "claude-gpt-5.6-sol";
          }
          {
            claude = "sonnet";
            copilot = "claude-sonnet-4.6";
            opencode = "openai/gpt-5.6-sol";
            codex = "gpt-5.6-sol";
          };
      model_provider = routedProvider;
      model_reasoning_effort = {
        codex = "medium";
      };
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
      model =
        routedModel
          {
            claude = "claude-gpt-oss-120b";
            codex = "claude-gpt-5.6-luna";
            opencode = "claude-gpt-5.6-luna";
          }
          {
            claude = "haiku";
            copilot = "claude-haiku-4.5";
            opencode = "openai/gpt-5.6-luna";
            codex = "gpt-5.6-luna";
          };
      model_provider = routedProvider;
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
      model =
        routedModel
          {
            claude = "claude-opus-5";
            codex = "claude-gpt-5.6-sol";
            opencode = "claude-gpt-5.6-sol";
          }
          {
            claude = "opus";
            copilot = "claude-opus-4.6";
            opencode = "openai/gpt-5.6-sol";
            codex = "gpt-5.6-sol";
          };
      model_provider = routedProvider;
      model_reasoning_effort.codex = "high";
      sandbox_mode.codex = "read-only";
      content = builtins.readFile (agentsBasePath + "/general/reviewer.md");
    };
    implementer = implementationAgent // {
      name = "implementer";
      description = "Bounded implementation specialist for one parent-scoped change or correction batch with focused validation.";
    };
    worker = implementationAgent // {
      name = "worker";
      description = "Execution worker for one bounded implementation or fix batch with focused validation.";
    };
  };

  gatewayAgents = {
    "gpt-5-3-codex-spark" = mkGatewayAgent {
      name = "gpt-5-3-codex-spark";
      alias = "claude-gpt-5.3-codex-spark";
      description = "OpenAI GPT 5.3 Codex Spark gateway worker for obvious lookups, mechanical edits, and focused low-risk checks.";
      reasoningEffort = "medium";
      write = true;
    };
    "gpt-5-6-luna" = mkGatewayAgent {
      name = "gpt-5-6-luna";
      alias = "claude-gpt-5.6-luna";
      description = "OpenAI GPT 5.6 Luna gateway worker for bounded reproduction, deterministic high-volume work, and broader validation.";
      reasoningEffort = "medium";
      write = true;
    };
    "gpt-5-6-terra" = mkGatewayAgent {
      name = "gpt-5-6-terra";
      alias = "claude-gpt-5.6-terra";
      description = "OpenAI GPT 5.6 Terra gateway worker for explicit model-selected tasks.";
      reasoningEffort = "medium";
      write = true;
    };
    "gpt-5-6-sol" = mkGatewayAgent {
      name = "gpt-5-6-sol";
      alias = "claude-gpt-5.6-sol";
      description = "OpenAI GPT 5.6 Sol gateway worker for hard diagnosis, architecture or code review, and high-confidence reasoning.";
      reasoningEffort = "high";
    };
    "gemini-3-6-flash" = mkGatewayAgent {
      name = "gemini-3-6-flash";
      alias = "claude-gemini-3.6-flash";
      description = "Google Gemini 3.6 Flash gateway worker for repository discovery, broad searches, noisy probes, and fast validation.";
      workspaceWrite = true;
    };
    "gemini-3-1-pro" = mkGatewayAgent {
      name = "gemini-3-1-pro";
      alias = "claude-gemini-3.1-pro";
      description = "Google Gemini 3.1 Pro gateway worker for ambiguous diagnosis, dependency reasoning, and independent review.";
    };
    "google-sonnet-4-6" = mkGatewayAgent {
      name = "google-sonnet-4-6";
      alias = "claude-antigravity-sonnet-4-6";
      description = "Google subscription Claude Sonnet 4.6 gateway worker for bounded implementation and routine debugging.";
      write = true;
    };
    "google-opus-4-6" = mkGatewayAgent {
      name = "google-opus-4-6";
      alias = "claude-antigravity-opus-4-6";
      description = "Google subscription Claude Opus 4.6 gateway worker for difficult read-only review, diagnosis, and planning critique.";
    };
    "gpt-oss-120b" = mkGatewayAgent {
      name = "gpt-oss-120b";
      alias = "claude-gpt-oss-120b";
      description = "Google GPT-OSS 120B gateway worker for noisy test execution, validation summaries, and inexpensive independent checks.";
      workspaceWrite = true;
    };
    "opus-5" = mkGatewayAgent {
      name = "opus-5";
      alias = "claude-opus-5";
      description = "Anthropic Opus 5 gateway worker for difficult implementation, plan or code review, and high-confidence diagnosis.";
      write = true;
    };
    "sonnet-5" = mkGatewayAgent {
      name = "sonnet-5";
      alias = "claude-sonnet-5";
      description = "Anthropic Sonnet 5 gateway worker for bounded implementation, correction batches, and focused validation.";
      write = true;
    };
  };

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

  renderClaudeFrontmatter = agent: ''
    ---
    name: ${agent.name}
    description: ${agent.claudeDescription or agent.description}
    tools: ${lib.concatStringsSep ", " agent.tools}
    model: ${agent.model.claude or agent.model}
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
      coreToolLines = map (tool: "  ${tool}: ${if isAllowed tool then "true" else "false"}") coreTools;
    in
    lib.concatStringsSep "\n" coreToolLines;

  renderOpenCodePermission =
    permission:
    if permission == null then
      ""
    else
      let
        render = key: value: "  ${key}: ${toString value}";
      in
      ''
        permission:
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList render permission)}
      '';

  renderOpenCodeFrontmatter = agent: ''
    ---
    description: ${agent.description}
    mode: ${agent.mode or "all"}
    model: ${agent.model.opencode or agent.model}

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
      name: ${builtins.toJSON agent.name}
      description: ${builtins.toJSON agent.description}
      ${lib.optionalString (model != null) "model: ${builtins.toJSON model}"}
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
      inherit (agent) name;
      inherit (agent) description;
      developer_instructions = lib.trim agent.content;
    }
    // lib.optionalAttrs (model != null) {
      inherit model;
    }
    // lib.optionalAttrs (modelReasoningEffort != null) {
      model_reasoning_effort = modelReasoningEffort;
    }
    // lib.optionalAttrs (modelProvider != null) {
      model_provider = modelProvider;
    }
    // lib.optionalAttrs (sandboxMode != null) {
      sandbox_mode = sandboxMode;
    }
    // lib.optionalAttrs (agent ? nickname_candidates) {
      inherit (agent) nickname_candidates;
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
