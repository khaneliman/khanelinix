{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.apps.vscode;
in
{
  options.khanelinix.apps.vscode = with types; {
    enable = mkBoolOpt false "Whether or not to enable vscode.";
  };

  config = mkIf cfg.enable {
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

    home.file = {
      ".vscode/argv.json".text = builtins.toJSON {
        "enable-crash-reporter" = true;
        "crash-reporter-id" = "53a6c113-87c4-4f20-9451-dd67057ddb95";
        "password-store" = "gnome";
      };
    };
  };
}
