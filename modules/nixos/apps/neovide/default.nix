{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.apps.neovide;
in
{
  options.khanelinix.apps.neovide = {
    enable = mkBoolOpt false "Whether or not to enable neovide.";
  };

  config =
    mkIf cfg.enable { environment.systemPackages = with pkgs; [ neovide ]; };
}
