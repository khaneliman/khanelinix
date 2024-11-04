_: _final: prev: {
  # TODO: remove after https://github.com/NixOS/nixpkgs/pull/352621 is available
  yabai = prev.yabai.overrideAttrs (_oldAttrs: rec {
    version = "7.1.5";
    src = prev.fetchzip {
      url = "https://github.com/koekeishiya/yabai/releases/download/v${version}/yabai-v${version}.tar.gz";
      hash = "sha256-o+9Z3Kxo1ff1TZPmmE6ptdOSsruQzxZm59bdYvhRo3c=";
    };
  });
}
