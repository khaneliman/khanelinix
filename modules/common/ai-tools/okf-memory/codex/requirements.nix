{
  SessionStart = [
    {
      matcher = "startup|resume";
      hooks = [
        {
          type = "command";
          command = "sh /etc/codex/hooks/okf-memory-session-start.sh";
        }
      ];
    }
  ];

  UserPromptSubmit = [
    {
      hooks = [
        {
          type = "command";
          command = "sh /etc/codex/hooks/okf-memory-user-prompt-submit.sh";
        }
      ];
    }
  ];
}
