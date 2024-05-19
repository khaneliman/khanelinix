{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.suites.photo;
in
{
  options.khanelinix.suites.photo = {
    enable = mkBoolOpt false "Whether or not to enable photo configuration.";
  };

  config = mkIf cfg.enable { home.packages = with pkgs; lib.optionals stdenv.isLinux [ digikam ]; };
}