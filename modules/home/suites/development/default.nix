{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.development;
in
{
  options.khanelinix.suites.development = {
    enable =
      mkBoolOpt false
        "Whether or not to enable common development configuration.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      cpplint
    ];

    khanelinix = {
      apps = {
        vscode = enabled;
      };

      cli-apps = {
        astronvim = {
          enable = true;
          default = true;
        };
        helix = enabled;
        lazygit = enabled;
      };

      tools = {
        oh-my-posh = enabled;
      };
    };
  };
}
