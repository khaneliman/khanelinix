{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.tools.toilet;
in {
  options.khanelinix.tools.toilet = with types; {
    enable = mkBoolOpt false "Whether or not to enable toilet.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      toilet
    ];
  };
}
