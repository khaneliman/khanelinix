{ inputs, ... }:
_final: prev: {
  # NOTE: nixpkgs updated wireplumber to 0.5, but upstream restricts to 0.4.
  # TODO: remove after upstreamed package hits unstable
  waybar = inputs.nixpkgs-wayland.packages.${prev.system}.waybar.override {
    wireplumber = prev.wireplumber.overrideAttrs rec {
      version = "0.4.17";
      src = prev.fetchFromGitLab {
        domain = "gitlab.freedesktop.org";
        owner = "pipewire";
        repo = "wireplumber";
        rev = version;
        hash = "sha256-vhpQT67+849WV1SFthQdUeFnYe/okudTQJoL3y+wXwI=";
      };
    };
  };
}
