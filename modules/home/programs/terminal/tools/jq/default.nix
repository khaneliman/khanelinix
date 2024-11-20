{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.programs.terminal.tools.jq;
in
{
  options.khanelinix.programs.terminal.tools.jq = {
    enable = mkBoolOpt false "Whether or not to enable jq.";
  };

  config = mkIf cfg.enable {
    programs.jq = {
      enable = true;
      package = pkgs.jq;
    };
  };
}
