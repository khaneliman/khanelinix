{
  lib,
  mkShell,
  pkgs,
  ...
}:
let
  ng = pkgs.writeShellScriptBin "ng" ''
    if [ -x ./node_modules/.bin/ng ]; then
      exec ./node_modules/.bin/ng "$@"
    fi

    echo "No local Angular CLI found."
    echo "Install it in your project first:"
    echo "  npm install -D @angular/cli"
    echo "  pnpm add -D @angular/cli"
    echo "  yarn add -D @angular/cli"
    echo "  bun add -d @angular/cli"
    exit 1
  '';

  angularPackages = with pkgs; [
    ng
    bun
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
    echo "🅰️  Angular CLI wrapper: ng (uses local node_modules/.bin/ng)"
    echo "📦 Package managers: npm, pnpm, yarn, bun"
    echo "💡 First install CLI in-project: npm/pnpm/yarn/bun add -D @angular/cli"
  '';
}
