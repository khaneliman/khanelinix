{
  SessionStart = [
    {
      matcher = "startup|resume|clear|compact";
      hooks = [
        {
          type = "command";
          command = "python3 /etc/codex/hooks/planning-with-files/session_start.py";
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
          command = "python3 /etc/codex/hooks/planning-with-files/user_prompt_submit.py";
        }
      ];
    }
  ];

  Stop = [
    {
      hooks = [
        {
          type = "command";
          command = "python3 /etc/codex/hooks/planning-with-files/stop.py";
          timeout = 30;
        }
      ];
    }
  ];
}
