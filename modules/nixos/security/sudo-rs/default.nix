{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.security.sudo-rs;
in
{
  options.khanelinix.security.sudo-rs = {
    enable = mkBoolOpt false "Whether or not to replace sudo with sudo-rs.";
  };

  config = mkIf cfg.enable {
    security.sudo-rs = {
      enable = true;
      package = pkgs.sudo-rs;

      wheelNeedsPassword = false;

      # extraRules = [
      #   {
      #     noPass = true;
      #     users = [ config.khanelinix.user.name ];
      #   }
      # ];
    };
  };
}
