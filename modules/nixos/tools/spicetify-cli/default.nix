{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.tools.spicetify-cli;
in
{
  options.khanelinix.tools.spicetify-cli = {
    enable = mkBoolOpt false "Whether or not to enable spicetify-cli.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      spicetify-cli
    ];
  };
}
