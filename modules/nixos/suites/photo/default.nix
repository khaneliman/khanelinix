{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.photo;
in
{
  options.khanelinix.suites.photo = with types; {
    enable = mkBoolOpt false "Whether or not to enable photo configuration.";
  };

  config = mkIf cfg.enable {

    environment.systemPackages = with pkgs; [
      digikam
    ];
  };
}
