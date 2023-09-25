{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.internal) mkBoolOpt mkOpt;

  cfg = config.khanelinix.security.sops;
in
{
  options.khanelinix.security.sops = {
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
