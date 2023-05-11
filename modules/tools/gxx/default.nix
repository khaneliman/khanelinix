{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.tools.gxx;
in
{
  options.khanelinix.tools.gxx = with types; {
    enable = mkBoolOpt false "Whether or not to enable gxx.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      libcxx
      libcxxStdenv
    ];
  };
}
