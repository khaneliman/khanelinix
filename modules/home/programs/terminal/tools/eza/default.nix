{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe mkForce mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.programs.terminal.tools.eza;
in
{
  options.khanelinix.programs.terminal.tools.eza = {
    enable = mkBoolOpt false "Whether or not to enable eza.";
  };

  config = mkIf cfg.enable {
    programs.eza = {
      enable = true;
      package = pkgs.eza;

      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;

      icons = true;
      git = true;
    };

    home.shellAliases = {
      la = mkForce "${getExe pkgs.eza} -lah --tree";
      tree = mkForce "${getExe pkgs.eza} --tree --icons=always";
    };
  };
}
