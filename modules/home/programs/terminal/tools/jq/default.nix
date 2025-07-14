{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.jq;
in
{
  options.khanelinix.programs.terminal.tools.jq = {
    enable = lib.mkEnableOption "jq";
  };

  config = mkIf cfg.enable {
    programs.jq = {
      enable = true;
      package = pkgs.jq;
    };
  };
}
