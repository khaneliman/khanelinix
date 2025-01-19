{
  config,
  khanelinix-lib,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (khanelinix-lib) mkBoolOpt;

  cfg = config.khanelinix.suites.development;
in
{
  options.khanelinix.suites.development = {
    enable = mkBoolOpt false "Whether or not to enable common development configuration.";
  };

  config = mkIf cfg.enable {
    environment.variables = {
      LLDB_DEBUGSERVER_PATH = "${pkgs.lldb.out}/bin/lldb-server";
    };

    homebrew = {
      casks = [
        "cutter"
        "docker"
        "electron"
        "powershell"
      ];

      masApps = mkIf config.khanelinix.tools.homebrew.masEnable {
        "Patterns" = 429449079;
        "Xcode" = 497799835;
      };
    };
  };
}
