{ mkShell
, pkgs
, ...
}:
mkShell {
  buildInputs = with pkgs; [
    vimPlugins.nvim-treesitter-parsers.angular
    vscode-extensions.angular.ng-template
    nodejs-18_x
    yarn
    nodePackages."@angular/cli"
  ];

  shellHook = ''

    echo 🔨 Angular DevShell


  '';

}
