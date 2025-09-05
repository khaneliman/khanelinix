{ pkgs, ... }:
{
  rust = {
    name = "rust";
    packages = with pkgs; [
      cargo
      clippy
      rust-analyzer
      rustc
      rustfmt
    ];
    devshell.motd = "🔨 Rust DevShell";
  };
}
