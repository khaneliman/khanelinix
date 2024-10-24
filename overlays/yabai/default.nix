_: _final: prev: {
  # TODO: remove after https://github.com/NixOS/nixpkgs/pull/350496 is available
  yabai = prev.yabai.overrideAttrs (_oldAttrs: rec {
    version = "7.1.4";
    src = prev.fetchzip {
      url = "https://github.com/koekeishiya/yabai/releases/download/v${version}/yabai-v${version}.tar.gz";
      hash = "sha256-DAHZwEhPIBIfR2V+jTKje1msB8OMKzwGYgYnDql8zb0=";
    };
  });
}
