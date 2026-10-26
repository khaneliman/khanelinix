let
  hook = event: {
    hooks = [
      {
        type = "command";
        command = "python3 /etc/codex/hooks/worker-lanes/worker_lanes_hook.py codex ${event}";
        timeout = 5;
      }
    ];
  };
in
{
  PostToolUse = [ (hook "post-tool") ];
  UserPromptSubmit = [ (hook "user-prompt") ];
  Stop = [ (hook "stop") ];
  # Fires in the parent session when a native child finishes, even while the
  # parent turn is idle.
  SubagentStop = [ (hook "subagent-stop") ];
}
