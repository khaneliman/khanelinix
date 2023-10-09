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
    home = {
      packages = with pkgs; [
        cpplint
      ];

      shellAliases = {
        prefetch-sri = "nix store prefetch-file $1";
      };
    };

    khanelinix = {
      apps = {
        vscode = enabled;
      };

      cli-apps = {
        helix = enabled;
        lazygit = enabled;
        neovim = {
          enable = true;
          default = true;
        };
      };

      tools = {
        oh-my-posh = enabled;
      };
    };
  };
}
