{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.programs.terminal.tools.nh;
in
{
  options.${namespace}.programs.terminal.tools.nh = {
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
