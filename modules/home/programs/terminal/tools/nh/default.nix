{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.nh;

  # Get log paths from Darwin system config if available, otherwise use defaults
  logPaths =
    if
      pkgs.stdenv.hostPlatform.isDarwin
      && (osConfig.khanelinix.programs.terminal.tools.nh.enable or false)
    then
      osConfig.khanelinix.programs.terminal.tools.nh.logPaths
    else
      {
        stdout = "${config.home.homeDirectory}/Library/Logs/nh/nh.out.log";
        stderr = "${config.home.homeDirectory}/Library/Logs/nh/nh.err.log";
      };
in
{
  options.khanelinix.programs.terminal.tools.nh = {
    enable = lib.mkEnableOption "nh";
  };

  config = mkIf cfg.enable {
    programs.nh = {
      enable = true;

      clean = {
        enable = true;
      };

      flake = "${config.home.homeDirectory}/khanelinix";
    };

    launchd.agents.nh-clean.config = {
      StandardErrorPath = logPaths.stderr;
      StandardOutPath = logPaths.stdout;
    };

    home = {
      sessionVariables = {
        NH_SEARCH_PLATFORM = 1;
      };
      shellAliases = {
        nixre = "nh ${if pkgs.stdenv.hostPlatform.isLinux then "os" else "darwin"} switch";
      };
    };
  };
}
