{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.lazygit;
in
{
  options.khanelinix.programs.terminal.tools.lazygit = {
    enable = lib.mkEnableOption "lazygit";
  };

  config = mkIf cfg.enable {
    programs.lazygit = {
      enable = true;

      settings = {
        gui = {
          authorColors = {
            "${config.khanelinix.user.fullName}" = "#c6a0f6";
            "dependabot[bot]" = "#eed49f";
          };
          branchColorPatterns = {
            "^main$" = "#ed8796";
            "^master$" = "#ed8796";
            "^dev" = "#8bd5ca";
          };
          nerdFontsVersion = "3";
        };
        git = {
          overrideGpg = true;
        };

        customCommands = import ./custom-commands.nix;
      };
    };
  };
}
