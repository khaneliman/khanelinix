{
  config,
  lib,
  osConfig ? { },
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.nh;

  userHome = config.home.homeDirectory;

  nhLogPaths = lib.attrByPath [ "khanelinix" "programs" "terminal" "tools" "nh" "logPaths" ] (
    if pkgs.stdenv.hostPlatform.isDarwin then
      {
        stdout = "${userHome}/Library/Logs/nh/nh.out.log";
        stderr = "${userHome}/Library/Logs/nh/nh.err.log";
      }
    else
      {
        stdout = "${userHome}/.local/state/nh/nh.out.log";
        stderr = "${userHome}/.local/state/nh/nh.err.log";
      }
  ) osConfig;
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

    launchd.agents.nh-clean.config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      StandardErrorPath = nhLogPaths.stderr;
      StandardOutPath = nhLogPaths.stdout;
      EnvironmentVariables = {
        PATH = "/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
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
