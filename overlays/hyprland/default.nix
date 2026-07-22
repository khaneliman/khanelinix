{ inputs }:
_final: prev: {
  # v0.56.0 guards deferred frame commits against outputs destroyed during
  # DPMS link retraining. Drop this overlay once the primary nixpkgs input
  # carries v0.56.0 or newer.
  hyprland =
    if prev.stdenv.hostPlatform.isLinux then
      (import inputs.nixpkgs-master {
        inherit (prev.stdenv.hostPlatform) system;
        inherit (prev) config;
      }).hyprland
    else
      prev.hyprland;
}
