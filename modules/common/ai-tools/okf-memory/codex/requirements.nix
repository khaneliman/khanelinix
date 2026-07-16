{
  SessionStart = [
    {
      matcher = "startup|resume|clear|compact";
      hooks = [
        {
          type = "command";
          command = "python3 /etc/codex/hooks/okf_memory_hook.py codex session-start";
        }
      ];
    }
  ];

  UserPromptSubmit = [
    {
      hooks = [
        {
          type = "command";
          command = "python3 /etc/codex/hooks/okf_memory_hook.py codex user-prompt";
        }
      ];
    }
  ];

  Stop = [
    {
      hooks = [
        {
          type = "command";
          command = "python3 /etc/codex/hooks/okf_memory_hook.py codex stop";
          timeout = 5;
        }
      ];
    }
  ];
}
