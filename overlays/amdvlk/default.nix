_: _final: prev: {
  # TODO: remove after available in unstable
  amdvlk = prev.amdvlk.override {
    glslang = prev.glslang.overrideAttrs (
      finalAttrs: _oldAttrs: {
        version = "15.0.0";
        src = prev.fetchFromGitHub {
          owner = "KhronosGroup";
          repo = "glslang";
          rev = "refs/tags/${finalAttrs.version}";
          hash = "sha256-QXNecJ6SDeWpRjzHRTdPJHob1H3q2HZmWuL2zBt2Tlw=";
        };
      }
    );
  };
}
