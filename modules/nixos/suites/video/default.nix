{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let

  cfg = config.${namespace}.suites.video;
in
{
  options.${namespace}.suites.video = {
    enable = lib.mkEnableOption "video configuration";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      kdePackages.k3b
    ];
  };
}
