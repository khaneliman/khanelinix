{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.tools.xclip;
in {
  options.khanelinix.tools.xclip = with types; {
    enable = mkBoolOpt false "Whether or not to enable xclip.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      xclip
    ];
  };
}
