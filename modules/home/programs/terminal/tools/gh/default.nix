{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.programs.terminal.tools.gh;
in
{
  options.${namespace}.programs.terminal.tools.gh = {
    enable = mkEnableOption "the gh CLI tool";

    gitCredentialHelper = {
      hosts = mkOption {
        type = types.listOf types.str;
        default = [
          "https://github.com"
          "https://gist.github.com"
        ];
        description = "A list of hosts for which gh should be used as a credential helper.";
        example = ''
          [ "github.com" "enterprise.github.com" ]
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    programs = {
      gh = {
        enable = true;

        extensions = with pkgs; [
          gh-notify # notifications
          gh-eco # explore the ecosystem
          gh-cal # contributions calender terminal viewer
          gh-poi # clean up local branches safely
        ];

        gitCredentialHelper = {
          enable = true;
          inherit (cfg.gitCredentialHelper) hosts;
        };

        settings = {
          version = "1";
        };
      };
      # dashboard with pull requests and issues
      gh-dash = enabled;
    };
  };
}
