{
  config,
  lib,

  pkgs,
  ...
}:
let
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt;

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
