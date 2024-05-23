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

  cfg = config.${namespace}.programs.terminal.tools.oh-my-posh;
in
{
  options.${namespace}.programs.terminal.tools.oh-my-posh = {
    enable = mkBoolOpt false "Whether or not to enable oh-my-posh.";
  };

  config = mkIf cfg.enable {
    programs.oh-my-posh = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      package = pkgs.oh-my-posh;
      settings = builtins.fromJSON (
        builtins.unsafeDiscardStringContext (builtins.readFile ./config.json)
      );
    };
  };
}
