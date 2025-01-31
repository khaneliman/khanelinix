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
  inherit (lib.${namespace}) mkBoolOpt enabled;
  inherit (inputs) nix-gaming;

  cfg = config.${namespace}.suites.games;
in
{
  options.${namespace}.suites.games = {
    enable = mkBoolOpt false "Whether or not to enable common games configuration.";
  };

  config = mkIf cfg.enable {
    # TODO: sober/roblox?
    home.packages = with pkgs; [
      (bottles.override {
        extraPkgs = pkgs: [
          nix-gaming.packages.${system}.wine-ge
        ];
        removeWarningPopup = true;
      })
      heroic
      lutris
      prismlauncher
      proton-caller
      protontricks
      protonup-ng
      protonup-qt
      wowup-cf
      nix-gaming.packages.${system}.roblox-player
    ];

    khanelinix = {
      programs = {
        terminal = {
          tools = {
            wine = lib.mkDefault enabled;
          };
        };
      };
    };
  };
}
