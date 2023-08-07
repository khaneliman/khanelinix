{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.apps.vscode;
in
{
  options.khanelinix.apps.vscode = with types; {
    enable = mkBoolOpt false "Whether or not to enable vscode.";
  };

  config =
    mkIf cfg.enable {
      programs.vscode = {
        enable = true;
        enableUpdateCheck = true;
        package = pkgs.vscode;

        extensions = with pkgs.vscode-extensions; [
          catppuccin.catppuccin-vsc
          eamodio.gitlens
          formulahendry.auto-close-tag
          formulahendry.auto-rename-tag
          github.vscode-pull-request-github
          github.vscode-github-actions
          gruntfuggly.todo-tree
          mkhl.direnv
          vscode-icons-team.vscode-icons
          wakatime.vscode-wakatime
        ];
      };
    };
}
