_: {
  rust = {
    name = "rust";

    languages.rust = {
      enable = true;
      channel = "stable";
      version = "latest";
      components = [
        "rustc"
        "cargo"
        "clippy"
        "rustfmt"
        "rust-analyzer"
      ];
      targets = [ ];
      rustflags = "";
      mold.enable = false;
    };

    enterShell = ''
      echo "🔨 Rust DevShell"
      echo "Rust $(rustc --version)"
      echo "Components: rustc, cargo, clippy, rustfmt, rust-analyzer"
    '';
  };
}
