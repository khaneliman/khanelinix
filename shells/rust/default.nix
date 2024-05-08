{ mkShell, pkgs, ... }:
mkShell {
  buildInputs = with pkgs; [
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
