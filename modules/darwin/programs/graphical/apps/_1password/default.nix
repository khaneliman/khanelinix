{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.programs.graphical.apps._1password;
in
{
  options.${namespace}.programs.graphical.apps._1password = {
    enable = lib.mkEnableOption "1password";
  };

  config = mkIf cfg.enable {
    programs = {
      _1password = {
        enable = true;
        package = pkgs._1password-cli;
      };
      _1password-gui = {
        enable = true;
        package = pkgs._1password-gui;
      };
    };

    homebrew = {
      masApps = mkIf config.${namespace}.tools.homebrew.masEnable {
        "1Password for Safari" = 1569813296;
      };
    };
  };
}
