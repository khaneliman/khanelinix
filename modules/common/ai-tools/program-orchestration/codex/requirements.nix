{
  SessionStart = [
    {
      matcher = "startup|resume|clear|compact";
      hooks = [
        {
          type = "command";
          command = "python3 /etc/codex/hooks/program-orchestration/program_context.py codex session-start";
          statusMessage = "Loading program context";
          timeout = 5;
        }
      ];
    }
  ];

  UserPromptSubmit = [
    {
      hooks = [
        {
          type = "command";
          command = "python3 /etc/codex/hooks/program-orchestration/program_context.py codex user-prompt";
          timeout = 5;
        }
      ];
    }
  ];
}
