{ pkgs, ... }:
{
  angular = {
    name = "angular";
    packages = with pkgs; [
      nodePackages."@angular/cli"
      nodejs_20
      pnpm
      vimPlugins.nvim-treesitter-parsers.angular
      vscode-extensions.angular.ng-template
      yarn
      typescript-language-server
      typescript
    ];
    devshell.motd = "🔨 Angular DevShell";
  };
}
