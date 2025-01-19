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
    dockerEnable = mkBoolOpt true "Whether or not to enable docker development configuration.";
    aiEnable = mkBoolOpt true "Whether or not to enable ai development configuration.";
  };

  config = mkIf cfg.enable {
    environment.variables = {
      LLDB_DEBUGSERVER_PATH = "${pkgs.lldb.out}/bin/lldb-server";
    };

    homebrew = {
      casks =
        [
          "cutter"
          "electron"
          "powershell"
        ]
        ++ lib.optionals cfg.dockerEnable [ "docker" ]
        ++ lib.optionals cfg.aiEnable [ "ollamac" ];

      masApps = mkIf config.khanelinix.tools.homebrew.masEnable {
        "Patterns" = 429449079;
        "Xcode" = 497799835;
      };
    };
  };
}
