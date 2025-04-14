{
  config,
  inputs,
  lib,
  namespace,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.programs.terminal.tools.nh;
in
{
  options.${namespace}.programs.terminal.tools.nh = {
    enable = lib.mkEnableOption "nh";
  };

  config = mkIf cfg.enable {
    programs.nh = {
      enable = true;

      clean = {
        enable = !osConfig.nix.gc.automatic;
      };
      flake = inputs.self.outPath;
    };
    home.sessionVariables = {
      NH_SEARCH_PLATFORM = 1;
    };
  };
}
