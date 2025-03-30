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
    ;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.programs.terminal.tools.gh;
in
{
  options.${namespace}.programs.terminal.tools.gh = {
    enable = mkEnableOption "Git";
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
          hosts = [
            "https://github.com"
            "https://gist.github.com"
            "https://core-bts-02@dev.azure.com"
          ];
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
