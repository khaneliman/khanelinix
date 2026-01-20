{ lib, ... }:
let
  inherit (lib) mapAttrs;

  agentsBasePath = ./agents;

  agents = {
    code-reviewer = {
      name = "code-reviewer";
      description = "Code review specialist for analyzing changes, ensuring quality, and creating atomic commits. Use for code reviews and committing changes.";
      tools = [
        "Read"
        "Bash"
        "Grep"
        "Glob"
      ];
      model = {
        claude = "sonnet";
        gemini = "gemini-3-pro-preview";
        opencode = "anthropic/claude-sonnet-4-5";
      };
      permission = {
        edit = "deny";
        bash = "ask";
      };
      content = builtins.readFile (agentsBasePath + "/general/code-reviewer.md");
    };
    debugger = {
      name = "debugger";
      description = "Debugging specialist for errors, exceptions, test failures, and unexpected behavior. Use when encountering any issues that need root cause analysis.";
      tools = [
        "Read"
        "Edit"
        "Bash"
        "Grep"
        "Glob"
      ];
      model = {
        claude = "sonnet";
        gemini = "gemini-3-pro-preview";
        opencode = "anthropic/claude-opus-4-5";
      };
      permission = {
        edit = "ask";
        bash = "ask";
      };
      content = builtins.readFile (agentsBasePath + "/general/debugger.md");
    };
    doc-writer = {
      name = "doc-writer";
      description = "Documentation specialist for writing READMEs, API docs, guides, and technical documentation. Use when documentation work would benefit from isolated context.";
      tools = [
        "Read"
        "Write"
        "Edit"
        "Grep"
        "Glob"
      ];
      model = {
        claude = "haiku";
        gemini = "gemini-2.5-flash";
        opencode = "anthropic/claude-sonnet-4-5";
      };
      permission = {
        edit = "deny";
        bash = "ask";
      };
      content = builtins.readFile (agentsBasePath + "/general/doc-writer.md");
    };
    refactorer = {
      name = "refactorer";
      description = "Code refactoring specialist for improving code structure, readability, and maintainability without changing behavior. Use for focused refactoring tasks in isolated context.";
      tools = [
        "Read"
        "Edit"
        "Write"
        "Grep"
        "Glob"
        "Bash"
      ];
      model = {
        claude = "sonnet";
        gemini = "gemini-3-pro-preview";
        opencode = "anthropic/claude-sonnet-4-5";
      };
      permission = {
        edit = "ask";
        bash = "ask";
      };
      content = builtins.readFile (agentsBasePath + "/general/refactorer.md");
    };
    test-runner = {
      name = "test-runner";
      description = "Test execution specialist. Use after code changes to run tests, analyze failures, and suggest fixes. Keeps verbose test output out of main conversation.";
      tools = [
        "Read"
        "Bash"
        "Grep"
        "Glob"
        "Edit"
      ];
      model = {
        claude = "haiku";
        gemini = "flash";
        opencode = "anthropic/claude-haiku-4-5";
      };
      permission = {
        edit = "ask";
        bash = "ask";
      };
      content = builtins.readFile (agentsBasePath + "/general/test-runner.md");
    };
    nix-builder = {
      name = "nix-builder";
      description = "Nix build and evaluation specialist. Use for running nix builds, checking flakes, debugging evaluation errors, and validating Nix configurations.";
      tools = [
        "Read"
        "Bash"
        "Grep"
        "Glob"
      ];
      model = {
        claude = "haiku";
        gemini = "flash";
        opencode = "anthropic/claude-haiku-4-5";
      };
      permission = {
        edit = "deny";
        bash = {
          "*" = "ask";
          "nix build*" = "allow";
          "nix flake*" = "allow";
          "nix eval*" = "allow";
        };
      };
      content = builtins.readFile (agentsBasePath + "/nix/nix-builder.md");
    };
  };

  # Claude Code expects YAML frontmatter with: name, description, tools (comma-sep), model
  renderClaudeFrontmatter = agent: ''
    ---
    name: ${agent.name}
    description: ${agent.description}
    tools: ${lib.concatStringsSep ", " agent.tools}
    model: ${agent.model.claude or agent.model}
    ---
  '';

  renderClaudeAgent = agent: ''
    ${lib.trim (renderClaudeFrontmatter agent)}

    ${lib.trim agent.content}
  '';

  # Render permission value (string or attrset with glob patterns)
  renderPermissionValue =
    indent: value:
    if builtins.isString value then
      value
    else if builtins.isAttrs value then
      lib.concatStringsSep "\n" (
        lib.mapAttrsToList (pattern: action: "${indent}  \"${pattern}\": ${action}") value
      )
    else
      "ask";

  # Render permissions block
  renderPermissions =
    indent: perms:
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        key: value:
        if builtins.isAttrs value then
          "${indent}${key}:\n${renderPermissionValue indent value}"
        else
          "${indent}${key}: ${value}"
      ) perms
    );

  # OpenCode expects YAML frontmatter with: description, mode, model, permission
  renderOpenCodeFrontmatter = agent: ''
    ---
    description: ${agent.description}
    mode: subagent
      model: ${agent.model.opencode or agent.model}

    permission:
    ${renderPermissions "  " agent.permission}
    ---
  '';

  renderOpenCodeAgent = agent: ''
    ${lib.trim (renderOpenCodeFrontmatter agent)}

    ${lib.trim agent.content}
  '';

  toClaudeMarkdown = mapAttrs (_name: renderClaudeAgent) agents;
  toOpenCodeMarkdown = mapAttrs (_name: renderOpenCodeAgent) agents;
in
{
  inherit agents toClaudeMarkdown toOpenCodeMarkdown;
}
