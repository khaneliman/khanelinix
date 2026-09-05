{
  aiTools,
  lib,
  pkgs,
  ...
}:
let
  # -P stops Python from adding the bare store path to sys.path, which made it
  # scan /nix/store on the first import of every hook run.
  command = event: "${lib.getExe pkgs.python3} -P ${aiTools.okfMemory.hook} claude ${event}";
  hook = event: {
    type = "command";
    command = command event;
    timeout = 5;
  };
in
{
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
