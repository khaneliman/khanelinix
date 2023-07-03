{ lib, config, ... }:

let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkOpt enabled;

  cfg = config.khanelinix.services.nix-daemon;
in
{
  options.khanelinix.services.nix-daemon = {
    enable = mkOpt types.bool true "Whether to enable the Nix daemon.";
  };

  config = mkIf cfg.enable {
    services.nix-daemon = enabled;
  };
}
