{
  aiTools,
  lib,
  pkgs,
  ...
}:
let
  command = event: "${lib.getExe pkgs.python3} ${aiTools.okfMemory.hook} claude ${event}";
  hook = event: {
    type = "command";
    command = command event;
    timeout = 5;
  };
in
{
  SessionStart = [
    {
      matcher = "*";
      hooks = [ (hook "session-start") ];
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
