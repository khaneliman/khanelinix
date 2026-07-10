{
  allow_managed_hooks_only = true;

  features.hooks = true;

  hooks = {
    managed_dir = "/etc/codex/hooks";

    SessionStart = [
      {
        matcher = "startup|resume|clear|compact";
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
