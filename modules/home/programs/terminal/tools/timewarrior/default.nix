{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.programs.terminal.tools.timewarrior;
  taskwarriorEnabled = config.khanelinix.programs.terminal.tools.taskwarrior.enable;
  taskwarriorHooks = "${config.programs.taskwarrior.dataLocation}/hooks";
in
{
  options.khanelinix.programs.terminal.tools.timewarrior = {
    enable = lib.mkEnableOption "Timewarrior time tracking";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.timewarrior ] ++ lib.optionals taskwarriorEnabled [ pkgs.python3 ];

    home.file."${taskwarriorHooks}/on-modify.timewarrior" = lib.mkIf taskwarriorEnabled {
      source = "${pkgs.timewarrior}/share/doc/timew/ext/on-modify.timewarrior";
      executable = true;
    };
  };
}
