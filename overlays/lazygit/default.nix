{ ... }: _final: prev: {
  lazygit = prev.lazygit.overrideAttrs (oldAttrs: {
    version = "0.40.2";

    src = prev.fetchFromGitHub {
      owner = "jesseduffield";
      repo = "lazygit";
      rev = "v0.40.2";
      hash = "sha256-xj5WKAduaJWA3NhWuMsF5EXF91+NTGAXkbdhpeFqLxE=";
    };
  });
}
