{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.suites.development;
in
{
  options.${namespace}.suites.development = {
    enable = mkBoolOpt false "Whether or not to enable common development configuration.";
    dockerEnable = mkBoolOpt true "Whether or not to enable docker development configuration.";
    aiEnable = mkBoolOpt false "Whether or not to enable ai development configuration.";
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

      masApps = mkIf config.${namespace}.tools.homebrew.masEnable {
        "Patterns" = 429449079;
        "Xcode" = 497799835;
      };
    };
  };
}
