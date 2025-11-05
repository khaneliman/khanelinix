{
  mkShell,
  pkgs,
  lib,
  ...
}:
let
  reactPackages =
    with pkgs;
    [
      # Modern React tooling (replacing deprecated create-react-app)
      nodejs_22
      pnpm
      yarn
      bun
      typescript-language-server
      typescript
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      react-native-debugger
    ];
in
mkShell {
  packages = reactPackages;

  shellHook = ''
    echo "🔨 React DevShell"
    echo ""
    echo "📦 Available tools:"
    ${lib.concatMapStringsSep "\n" (
      pkg: ''echo "  - ${pkg.pname or pkg.name or "unknown"} (${pkg.version or "unknown"})"''
    ) reactPackages}
    echo ""
    echo "⚛️  Modern React tooling with Vite"
    echo "📦 Package managers: npm, pnpm, yarn, bun"
  '';
}
