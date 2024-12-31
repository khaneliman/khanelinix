{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.suites.video;
in
{
  options.${namespace}.suites.video = {
    enable = mkBoolOpt false "Whether or not to enable video configuration.";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # FIXME: broken nixpkgs
      # kdePackages.k3b
    ];
  };
}
