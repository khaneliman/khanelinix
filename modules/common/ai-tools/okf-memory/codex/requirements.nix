{
  SessionStart = [
    {
      matcher = "startup|resume";
      hooks = [
        {
          type = "command";
          command = "python3 /etc/codex/hooks/okf_memory_context.py";
        }
      ];
    }
  ];

  UserPromptSubmit = [
    {
      hooks = [
        {
          type = "command";
          command = "python3 /etc/codex/hooks/okf_memory_context.py";
        }
      ];
    }
  ];
}
