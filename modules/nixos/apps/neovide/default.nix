{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.apps.neovide;
in
{
  options.khanelinix.apps.neovide = with types; {
    enable = mkBoolOpt false "Whether or not to enable neovide.";
  };

  config =
    mkIf cfg.enable { environment.systemPackages = with pkgs; [ neovide ]; };
}
