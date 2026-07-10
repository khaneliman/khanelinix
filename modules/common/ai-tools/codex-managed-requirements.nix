{
  allow_managed_hooks_only = true;

  features.hooks = true;

  hooks = {
    managed_dir = "/etc/codex/hooks";

    SessionStart = [
      {
        matcher = "startup|resume";
        hooks = [
          {
            type = "command";
            command = "python3 /etc/codex/hooks/session_start.py";
            statusMessage = "Loading planning context";
          }
        ];
      }
    ];

    UserPromptSubmit = [
      {
        hooks = [
          {
            type = "command";
            command = "python3 /etc/codex/hooks/user_prompt_submit.py";
          }
        ];
      }
    ];

    PreToolUse = [
      {
        matcher = "Bash";
        hooks = [
          {
            type = "command";
            command = "python3 /etc/codex/hooks/pre_tool_use.py";
            statusMessage = "Checking plan before Bash";
          }
        ];
      }
    ];

    PermissionRequest = [
      {
        hooks = [
          {
            type = "command";
            command = "python3 /etc/codex/hooks/permission_request.py";
          }
        ];
      }
    ];

    PostToolUse = [
      {
        matcher = "Bash";
        hooks = [
          {
            type = "command";
            command = "python3 /etc/codex/hooks/post_tool_use.py";
            statusMessage = "Reviewing Bash against plan";
          }
        ];
      }
    ];

    PreCompact = [
      {
        matcher = "*";
        hooks = [
          {
            type = "command";
            command = "sh /etc/codex/hooks/pre-compact.sh";
            statusMessage = "Preparing planning context before compact";
          }
        ];
      }
    ];

    Stop = [
      {
        hooks = [
          {
            type = "command";
            command = "python3 /etc/codex/hooks/stop.py";
            timeout = 30;
          }
        ];
      }
    ];
  };
}
