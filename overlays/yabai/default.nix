_: _final: prev: {
  yabai = prev.yabai.overrideAttrs (old: rec {
    version = "7.0.4";

    src = prev.fetchzip {
      url = "https://github.com/koekeishiya/yabai/releases/download/v${version}/yabai-v${version}.tar.gz";
      hash = "sha256-eOgdCW3BEB9vn9lui7Ib6uWl5MSAnHh3ztqHCWshCv8=";
    };
  });
}
