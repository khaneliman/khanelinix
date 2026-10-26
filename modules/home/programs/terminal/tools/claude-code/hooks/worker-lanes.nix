{
  aiTools,
  lib,
  pkgs,
  ...
}:
let
  hook = event: {
    type = "command";
    command = "${lib.getExe pkgs.python3} -P ${aiTools.workerLanes.hook} claude ${event}";
    timeout = 5;
  };
in
{
  # Every tool call counts toward the drift reminder; sessions that never
  # launch a background worker exit before touching state.
  PostToolUse = [
    {
      matcher = "*";
      hooks = [ (hook "post-tool") ];
    }
  ];

  UserPromptSubmit = [
    {
      matcher = "*";
      hooks = [ (hook "user-prompt") ];
    }
  ];

  Stop = [
    {
      matcher = "";
      hooks = [ (hook "stop") ];
    }
  ];
}
