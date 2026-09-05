{
  aiTools,
  lib,
  pkgs,
  ...
}:
{
  Stop = [
    {
      matcher = "";
      hooks = [
        {
          type = "command";
          command = "${lib.getExe pkgs.python3} -P ${aiTools.technicalWriting.guard} hook claude";
          timeout = 5;
        }
      ];
    }
  ];
}
