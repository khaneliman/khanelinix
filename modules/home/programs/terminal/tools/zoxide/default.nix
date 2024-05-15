{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.programs.terminal.tools.zoxide;
in
{
  options.khanelinix.programs.terminal.tools.zoxide = {
    enable = mkBoolOpt false "Whether or not to enable zoxide.";
  };

  config = mkIf cfg.enable {
    programs.zoxide = {
      enable = true;
      package = pkgs.zoxide;

      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;

      options = [ "--cmd cd" ];
    };
  };
}
