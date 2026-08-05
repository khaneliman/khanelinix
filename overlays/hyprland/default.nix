{ inputs }:
_final: prev: {
  # Use nixpkgs-master until the primary nixpkgs input carries the glaze
  # relaxation from https://github.com/NixOS/nixpkgs/pull/549253.
  hyprland =
    if prev.stdenv.hostPlatform.isLinux then
      (import inputs.nixpkgs-master {
        inherit (prev.stdenv.hostPlatform) system;
        inherit (prev) config;
      }).hyprland
    else
      prev.hyprland;
}
