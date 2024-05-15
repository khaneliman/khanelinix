{ mkShell, pkgs, ... }:
mkShell {
  packages = with pkgs; [
    cargo
    clippy
    rust-analyzer
    rustc
    rustfmt
  ];

  shellHook = ''

    echo 🔨 Rust DevShell


  '';
}
