{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) getExe mkForce mkIf;
  inherit (lib.khanelinix) mkBoolOpt;

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

      arguments = [
        # Don't have ripgrep vomit a bunch of stuff on the screen
        # show a preview of the match
        "--max-columns=150"
        "--max-columns-preview"

        # ignore git files
        "--glob=!.git/*"

        "--smart-case"
      ];
    };

    home.shellAliases = {
      grep = mkForce (getExe config.programs.ripgrep.package);
    };
  };
}
