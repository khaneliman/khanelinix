let
  hook = timeout: event: {
    type = "command";
    command = "python3 /etc/codex/hooks/authority-gate/authority_gate.py codex ${event}";
    inherit timeout;
  };
in
{
  UserPromptSubmit = [
    {
      hooks = [ (hook 5 "user-prompt") ];
    }
  ];

  PreToolUse = [
    {
      matcher = "Bash|apply_patch";
      hooks = [ (hook 5 "pre-tool") ];
    }
  ];

  # Codex caps SessionEnd hooks at three seconds.
  SessionEnd = [
    {
      hooks = [ (hook 2 "session-end") ];
    }
  ];
}
