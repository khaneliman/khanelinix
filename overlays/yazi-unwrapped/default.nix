_: _final: prev: {
  # TODO: remove after https://github.com/NixOS/nixpkgs/pull/331563 in unstable
  yazi-unwrapped = prev.rustPlatform.buildRustPackage rec {
    pname = "yazi";
    version = "0.3.0";

    src = prev.fetchFromGitHub {
      owner = "sxyazi";
      repo = "yazi";
      rev = "v${version}";
      hash = "sha256-vK8P+6hn7NiympkQE8Bp45ZPqTO24VTSu0QwnXHfdXw=";
    };

    cargoLock = {
      lockFile = ./Cargo.lock;
      outputHashes = {
        "notify-6.1.1" = "sha256-5Ft2yvRPi2EaErcGBkF/3Xv6K7ijFGbdjmSqI4go/h4=";
      };
    };

    env.YAZI_GEN_COMPLETIONS = true;
    env.VERGEN_GIT_SHA = "Nixpkgs";
    env.VERGEN_BUILD_DATE = "2024-08-01";

    nativeBuildInputs = with prev; [ installShellFiles ];
    buildInputs =
      with prev;
      [ rust-jemalloc-sys ]
      ++ lib.optionals stdenv.isDarwin (with prev.darwin.apple_sdk.frameworks; [ Foundation ]);

    postInstall = ''
      installShellCompletion --cmd yazi \
        --bash ./yazi-boot/completions/yazi.bash \
        --fish ./yazi-boot/completions/yazi.fish \
        --zsh  ./yazi-boot/completions/_yazi

      install -Dm444 assets/yazi.desktop -t $out/share/applications
      install -Dm444 assets/logo.png $out/share/pixmaps/yazi.png
    '';

    passthru.updateScript.command = [ ./update.sh ];

    meta = {
      description = "Blazing fast terminal file manager written in Rust, based on async I/O";
      homepage = "https://github.com/sxyazi/yazi";
      license = prev.lib.licenses.mit;
      maintainers = with prev.lib.maintainers; [
        xyenon
        matthiasbeyer
        linsui
        eljamm
      ];
      mainProgram = "yazi";
    };
  };

  yazi = prev.yazi.override {
    extraPackages = with prev; [
      _7zz
      imagemagick
      chafa
    ];
  };
}
