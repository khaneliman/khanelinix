_: _final: prev: {
  # TODO: remove after https://github.com/NixOS/nixpkgs/pull/333699 is available
  yabai = prev.yabai.overrideAttrs (_oldAttrs: rec {
    version = "7.1.2";

    src = prev.fetchzip {
      url = "https://github.com/koekeishiya/yabai/releases/download/v${version}/yabai-v${version}.tar.gz";
      hash = "sha256-4ZJs7Xpou0Ek0CCCjbK47Nu/XPpuTpBDU8GJz5AsaUg=";
    };
  });
}
