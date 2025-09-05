{ pkgs, ... }:
{
  angular = {
    name = "angular";

    languages.javascript = {
      enable = true;
      npm.enable = true;
      yarn.enable = true;
      pnpm.enable = true;
    };

    packages = with pkgs; [
      nodePackages."@angular/cli"
      nodejs_20
      typescript-language-server
      typescript
      vimPlugins.nvim-treesitter-parsers.angular
      vscode-extensions.angular.ng-template
    ];

    enterShell = ''
      echo "🔨 Angular DevShell"
      echo "Node.js $(node --version)"
      echo "Angular CLI $(ng version --version 2>/dev/null || echo 'not available')"
    '';
  };
}
