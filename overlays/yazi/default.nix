_: _final: prev: {
  # TODO: remove overlay after nixos-unstable updated
  yazi-unwrapped = prev.yazi-unwrapped.overrideAttrs (old: rec {
    version = "0.2.4";

    src = prev.fetchFromGitHub {
      owner = "sxyazi";
      repo = "yazi";
      rev = "v0.2.4";
      hash = "sha256-c8fWWCOVBqQVdQch9BniCaJPrVEOCv35lLH8/hMIbvE=";
    };

    cargoDeps = old.cargoDeps.overrideAttrs (_: {
      inherit src;

      outputHash = "sha256-M/+iK7Gs1twyPhKSWjB81wYlxnGDU+xK+qLdMPDbfQQ=";
    });

    postInstall = ''
      installShellCompletion --cmd yazi \
       --bash ./yazi-boot/completions/yazi.bash \
       --fish ./yazi-boot/completions/yazi.fish \
       --zsh  ./yazi-boot/completions/_yazi
    '';
  });
}
