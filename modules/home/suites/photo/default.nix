{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.suites.photo;
in
{
  options.${namespace}.suites.photo = {
    enable = mkBoolOpt false "Whether or not to enable photo configuration.";
  };

  config = mkIf cfg.enable { home.packages = with pkgs; lib.optionals stdenv.isLinux [ digikam ]; };
}
