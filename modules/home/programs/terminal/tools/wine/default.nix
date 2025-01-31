{
  config,
  inputs,
  lib,
  pkgs,
  namespace,
  system,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  inherit (inputs) nix-gaming;

  cfg = config.${namespace}.programs.terminal.tools.wine;
in
{
  options.${namespace}.programs.terminal.tools.wine = {
    enable = mkBoolOpt false "Whether or not to enable Wine.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      winetricks
      nix-gaming.packages.${system}.wine-ge
    ];
  };
}
