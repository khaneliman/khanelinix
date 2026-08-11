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
          command = "${lib.getExe pkgs.python3} ${aiTools.technicalWriting.guard} hook claude";
          timeout = 5;
        }
      ];
    }
  ];
}
