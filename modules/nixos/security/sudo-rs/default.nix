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

  cfg = config.${namespace}.security.sudo-rs;
in
{
  options.${namespace}.security.sudo-rs = {
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
      #     users = [ config.${namespace}.user.name ];
      #   }
      # ];
    };
  };
}
