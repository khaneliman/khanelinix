{
  aiTools,
  lib,
  pkgs,
  ...
}:
{
  UserPromptSubmit = [
    {
      hooks = [
        {
          type = "command";
          command = "${lib.getExe pkgs.python3} -P ${aiTools.skillRouting.hook} claude user-prompt";
          timeout = 5;
        }
      ];
    }
  ];

  UserPromptExpansion = [
    {
      matcher = "github-toolkit";
      hooks = [
        {
          type = "command";
          command = "${lib.getExe pkgs.python3} -P ${aiTools.skillRouting.hook} claude prompt-expansion";
          timeout = 5;
        }
      ];
    }
  ];

  PreToolUse = [
    {
      matcher = "*";
      hooks = [
        {
          type = "command";
          command = "${lib.getExe pkgs.python3} -P ${aiTools.skillRouting.hook} claude pre-tool";
          timeout = 5;
        }
      ];
    }
  ];

  PostToolUse = [
    {
      matcher = "Skill";
      hooks = [
        {
          type = "command";
          command = "${lib.getExe pkgs.python3} -P ${aiTools.skillRouting.hook} claude post-tool";
          timeout = 5;
        }
      ];
    }
  ];

  PostCompact = [
    {
      hooks = [
        {
          type = "command";
          command = "${lib.getExe pkgs.python3} -P ${aiTools.skillRouting.hook} claude post-compact";
          timeout = 5;
        }
      ];
    }
  ];

  SessionEnd = [
    {
      hooks = [
        {
          type = "command";
          command = "${lib.getExe pkgs.python3} -P ${aiTools.skillRouting.hook} claude session-end";
          timeout = 5;
        }
      ];
    }
  ];
}
