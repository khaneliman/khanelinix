{ inputs, ... }:
{
  imports =
    with inputs;
    builtins.trace "NIXOS ----------------------------------------------" [
      disko.nixosModules.disko
      lanzaboote.nixosModules.lanzaboote
      nix-flatpak.nixosModules.nix-flatpak
      sops-nix.nixosModules.sops
    ];
}
