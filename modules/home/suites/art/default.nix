{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.suites.art;
in
{
  options.${namespace}.suites.art = {
    enable = lib.mkEnableOption "art configuration";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # FIXME: broken nixpkgs
      # blender
      gimp
      inkscape-with-extensions
    ];
  };
}
