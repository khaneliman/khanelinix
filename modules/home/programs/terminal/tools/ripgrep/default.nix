{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe mkForce mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.programs.terminal.tools.ripgrep;
in
{
  options.khanelinix.programs.terminal.tools.ripgrep = {
    enable = mkBoolOpt false "Whether or not to enable ripgrep.";
  };

  config = mkIf cfg.enable {
    programs.ripgrep = {
      enable = true;
      package = pkgs.ripgrep;

      arguments = [ ];
    };

    home.shellAliases = {
      grep = mkForce (getExe config.programs.ripgrep.package);
    };
  };
}
