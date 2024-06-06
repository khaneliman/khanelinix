_: _final: prev: {
  catppuccin-cursors = prev.catppuccin-cursors.overrideAttrs (oldAttrs: rec {
    version = "0.3.0";

    src = prev.fetchFromGitHub {
      owner = "catppuccin";
      repo = "cursors";
      rev = "v${version}";
      hash = "sha256-LJyBnXDUGBLOD4qPI7l0YC0CcqYTtgoMJc1H2yLqk9g=";
    };

    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ prev.hyprcursor ];

    buildPhase = ''
      runHook preBuild

      patchShebangs .

      just all_with_hyprcursor

      runHook postBuild
    '';
  });
}
