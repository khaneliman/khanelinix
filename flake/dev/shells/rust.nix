{
  lib,
  mkShell,
  pkgs,
  ...
}:
let
  rustPackages = with pkgs; [
    cargo
    clippy
    rust-analyzer
    rustc
    rustfmt
  ];
in
mkShell {
  packages = rustPackages;

  shellHook = ''
    echo "🔨 Rust DevShell"
    echo ""
    echo "📦 Available tools:"
    ${lib.concatMapStringsSep "\n" (
      pkg: ''echo "  - ${pkg.pname or pkg.name or "unknown"} (${pkg.version or "unknown"})"''
    ) rustPackages}
    echo ""
    echo "🦀 Ready for Rust development!"
  '';
}
