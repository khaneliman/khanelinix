{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.apps.logseq;
in
{
  options.khanelinix.apps.logseq = {
    enable = mkBoolOpt false "Whether or not to enable logseq.";
  };
  # TODO: remove module
  config =
    mkIf cfg.enable { environment.systemPackages = with pkgs; [ logseq ]; };
}
