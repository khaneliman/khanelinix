{
  aiTools,
  lib,
  pkgs,
  ...
}:
let
  # Unlike the single-file hooks, no -P: the gate imports its package from the
  # script's directory.
  command =
    event:
    "${lib.getExe pkgs.python3} ${aiTools.authorityGate.package}/authority_gate.py claude ${event}";
  hook = event: {
    type = "command";
    command = command event;
    timeout = 5;
  };
in
{
  UserPromptSubmit = [
    {
      hooks = [ (hook "user-prompt") ];
    }
  ];

  PreToolUse = [
    {
      matcher = "Bash|Write|Edit|MultiEdit";
      hooks = [ (hook "pre-tool") ];
    }
  ];

  SessionEnd = [
    {
      hooks = [ (hook "session-end") ];
    }
  ];
}
