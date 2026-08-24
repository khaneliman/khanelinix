{
  aiTools,
  lib,
  pkgs,
  ...
}:
let
  skill = aiTools.programOrchestration.canonicalSkill;
  command =
    event:
    lib.getExe (
      pkgs.writeShellApplication {
        name = "claude-program-context-${event}";
        runtimeInputs = [
          pkgs.git
          pkgs.python3
        ];
        text = ''
          exec python3 ${skill}/scripts/program_context.py claude ${event}
        '';
      }
    );
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
}
