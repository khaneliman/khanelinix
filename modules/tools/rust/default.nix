{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.tools.rust;
in {
  options.khanelinix.tools.rust = with types; {
    enable = mkBoolOpt false "Whether or not to enable rust.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      rust-bin.stable.latest.default
    ];
  };
}
