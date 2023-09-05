{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.apps.etcher;
in
{
  options.khanelinix.apps.etcher = with types; {
    enable = mkBoolOpt false "Whether or not to enable etcher.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # Etcher is currently broken in nixpkgs, temporarily replaced with
      # gnome disk utility.
      # etcher
      gnome.gnome-disk-utility
    ];
  };
}
