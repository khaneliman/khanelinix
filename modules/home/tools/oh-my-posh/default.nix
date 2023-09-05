{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.tools.oh-my-posh;
in
{
  options.khanelinix.tools.oh-my-posh = with types; {
    enable = mkBoolOpt false "Whether or not to enable oh-my-posh.";
  };

  config = mkIf cfg.enable {
    programs.oh-my-posh = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      package = pkgs.oh-my-posh;

      settings = builtins.fromJSON (builtins.unsafeDiscardStringContext (builtins.readFile ./config.json));
    };
  };
}
