{
  config,
  lib,
  khanelinix-lib,
  pkgs,
  ...
}:
let
  inherit (khanelinix-lib) mkBoolOpt;

  cfg = config.khanelinix.suites.video;
in
{
  options.khanelinix.suites.video = {
    enable = mkBoolOpt false "Whether or not to enable video configuration.";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # FIXME: broken nixpkgs
      # kdePackages.k3b
    ];
  };
}
