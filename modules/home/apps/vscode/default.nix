{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt enabled;

  cfg = config.khanelinix.apps.vscode;
in
{
  options.khanelinix.apps.vscode = {
    enable = mkBoolOpt false "Whether or not to enable vscode.";
  };

  config = mkIf cfg.enable {
    home.file = {
      ".vscode/argv.json" = mkIf config.khanelinix.security.keyring.enable {
        text = builtins.toJSON {
          "enable-crash-reporter" = true;
          "crash-reporter-id" = "53a6c113-87c4-4f20-9451-dd67057ddb95";
          "password-store" = "gnome";
        };
      };
    };

    khanelinix.tools.wakatime = enabled;

    programs.vscode = {
      enable = true;
      enableUpdateCheck = true;
      package = pkgs.vscode;

      extensions = with pkgs.vscode-extensions; [
        catppuccin.catppuccin-vsc
        eamodio.gitlens
        formulahendry.auto-close-tag
        formulahendry.auto-rename-tag
        github.vscode-github-actions
        github.vscode-pull-request-github
        gruntfuggly.todo-tree
        mkhl.direnv
        vscode-icons-team.vscode-icons
        wakatime.vscode-wakatime
      ];
    };

  };
}
