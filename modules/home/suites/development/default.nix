{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.development;
in
{
  options.khanelinix.suites.development = {
    enable = mkBoolOpt false "Whether or not to enable common development configuration.";
    dockerEnable = mkBoolOpt false "Whether or not to enable docker development configuration.";
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        jqp
        lazydocker
        onefetch
        postman
      ];

      shellAliases = {
        prefetch-sri = "nix store prefetch-file $1";
      };
    };

    khanelinix = {
      programs = {
        graphical = {
          editors = {
            vscode = enabled;
          };
        };

        terminal = {
          editors = {
            helix = enabled;
            neovim = {
              enable = true;
              default = true;
            };
          };

          tools = {
            node = enabled;
            oh-my-posh = enabled;
            lazydocker.enable = cfg.dockerEnable;
            lazygit = enabled;
            python = enabled;
          };
        };
      };
    };
  };
}
