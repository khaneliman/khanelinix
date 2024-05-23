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

  cfg = config.${namespace}.security.sops;
in
{
  options.${namespace}.security.sops = {
    enable = mkBoolOpt false "Whether to enable sops.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      age
      sops
      ssh-to-age
    ];
  };
}
