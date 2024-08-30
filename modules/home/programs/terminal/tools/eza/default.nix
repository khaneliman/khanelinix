{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.terminal.tools.eza;
in
{
  options.${namespace}.programs.terminal.tools.eza = {
    enable = mkBoolOpt false "Whether or not to enable eza.";
  };

  config = lib.mkIf cfg.enable {
    programs.eza = {
      enable = true;
      package = pkgs.eza;

      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;

      extraOptions = [
        "--group-directories-first"
        "--header"
      ];

      git = true;
      icons = true;
    };

    home.shellAliases = {
      la = lib.mkForce "${lib.getExe config.programs.eza.package} -lah --tree";
      tree = lib.mkForce "${lib.getExe config.programs.eza.package} --tree --icons=always";
    };
  };
}
