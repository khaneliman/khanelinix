{ inputs }:
_final: prev: {
  # v0.56.0 guards deferred frame commits against outputs destroyed during
  # DPMS link retraining. Drop this overlay once the primary nixpkgs input
  # carries v0.56.0 or newer.
  hyprland =
    if prev.stdenv.hostPlatform.isLinux then
      let
        hyprlandPkgs = import inputs.nixpkgs-master {
          inherit (prev.stdenv.hostPlatform) system;
          inherit (prev) config;
        };
      in
      hyprlandPkgs.hyprland.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          # Backport https://github.com/NixOS/nixpkgs/pull/549253.
          substituteInPlace CMakeLists.txt start/CMakeLists.txt hyprpm/CMakeLists.txt \
            --replace-fail "glaze 7...<8" "glaze"
        '';
      })
    else
      prev.hyprland;
}
