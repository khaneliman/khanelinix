{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.khanelinix.programs.terminal.tools.glab;
in
{
  options.khanelinix.programs.terminal.tools.glab = {
    enable = mkEnableOption "the glab CLI tool";

    gitCredentialHelper = {
      hosts = mkOption {
        type = types.listOf types.str;
        default = [
          "gitlab.com"
          "gitlab.com:443"
          "registry.gitlab.com"
        ];
        description = "A list of hosts for which glab should be used as a credential helper.";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.glab ];

    programs.git.settings.credential = builtins.listToAttrs (
      map (
        host:
        lib.nameValuePair host {
          helper = [
            ""
            "${lib.getExe pkgs.glab} auth git-credential"
          ];
        }
      ) cfg.gitCredentialHelper.hosts
    );
  };
}
