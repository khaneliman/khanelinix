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
        cpplint
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
      apps = {
        vscode = enabled;
      };

      cli-apps = {
        # FIX: nixpkg broke
        # helix = enabled;
        lazydocker.enable = cfg.dockerEnable;
        lazygit = enabled;
        neovim = {
          enable = true;
          default = true;
        };
      };

      tools = {
        node = enabled;
        oh-my-posh = enabled;
        python = enabled;
      };
    };
  };
}
