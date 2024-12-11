{ mkShell, pkgs, ... }:
mkShell {
  packages = with pkgs; [
    nodePackages."@angular/cli"
    nodejs-18_x
    pnpm
    vimPlugins.nvim-treesitter-parsers.angular
    vscode-extensions.angular.ng-template
    yarn
    typescript-language-server
    typescript
  ];

  shellHook = ''

    echo 🔨 Angular DevShell


  '';
}
