{
  lib,
  mkShell,
  pkgs,
  ...
}:
let
  angularPackages = with pkgs; [
    nodePackages."@angular/cli"
    nodejs_20
    pnpm
    vimPlugins.nvim-treesitter-parsers.angular
    vscode-extensions.angular.ng-template
    yarn
    typescript-language-server
    typescript
  ];
in
mkShell {
  packages = angularPackages;

  shellHook = ''
    echo "🔨 Angular DevShell"
    echo ""
    echo "📦 Available tools:"
    ${lib.concatMapStringsSep "\n" (
      pkg: ''echo "  - ${pkg.pname or pkg.name or "unknown"} (${pkg.version or "unknown"})"''
    ) angularPackages}
    echo ""
    echo "🅰️  Angular CLI ready"
    echo "📦 Package managers: npm, pnpm, yarn"
  '';
}
