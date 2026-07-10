{
  SessionStart = [
    {
      matcher = "startup|resume|clear|compact";
      hooks = [
        {
          type = "command";
          command = "python3 /etc/codex/hooks/okf_memory_context.py";
        }
      ];
    }
  ];
}
