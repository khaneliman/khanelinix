{ inputs, ... }:
{
  imports =
    with inputs;
    builtins.trace "HOME -------------------------------" [
      anyrun.homeManagerModules.default
      catppuccin.homeManagerModules.catppuccin
      hypr-socket-watch.homeManagerModules.default
      nix-index-database.hmModules.nix-index
      nur.hmModules.nur
      sops-nix.homeManagerModules.sops
    ];
}
