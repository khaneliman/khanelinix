{
  config,
  lib,

  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.graphical.apps._1password;
in
{
  options.khanelinix.programs.graphical.apps._1password = {
    enable = lib.mkEnableOption "1password";
  };

  config = mkIf cfg.enable {
    programs = {
      _1password = {
        # 1Password CLI documentation
        # See: https://developer.1password.com/docs/cli/
        enable = true;
        package = pkgs._1password-cli;
      };
      _1password-gui = {
        # 1Password GUI documentation
        # See: https://support.1password.com/
        enable = true;
        package = pkgs._1password-gui;
      };
    };

    homebrew = {
      masApps = mkIf config.khanelinix.tools.homebrew.masEnable {
        "1Password for Safari" = 1569813296;
      };
    };
  };
}
