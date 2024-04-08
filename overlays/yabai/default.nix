_: _final: prev: {
  yabai = prev.yabai.overrideAttrs (oldAttrs: rec {
    version = "7.1.0";

    src = prev.fetchzip {
      url = "https://github.com/koekeishiya/yabai/releases/download/v${version}/yabai-v${version}.tar.gz";
      hash = "sha256-88Sh2nizAQ0a0cnlnrkhb5x3VjHa372HhjHlmNjGdQ4=";
    };
  });
}
