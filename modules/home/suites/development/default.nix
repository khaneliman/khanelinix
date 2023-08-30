{ options
, config
, lib
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.development;
in
{
  options.khanelinix.suites.development = with types; {
    enable =
      mkBoolOpt false
        "Whether or not to enable common development configuration.";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      apps = {
        vscode = enabled;
      };

      cli-apps = {
        lazygit = enabled;
        astronvim = {
          enable = true;
          default = true;
        };
        helix = enabled;
      };

      tools = {
        oh-my-posh = enabled;
      };
    };
  };
}
