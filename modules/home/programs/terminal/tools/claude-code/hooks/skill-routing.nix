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

}
