{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.social.slack-term;
in
{
  options.khanelinix.programs.terminal.social.slack-term = {
    enable = lib.mkEnableOption "slack-term";
  };

  config = mkIf cfg.enable {
    # Slack-term documentation
    # See: https://github.com/erroneousboat/slack-term
    home.packages = [ pkgs.slack-term ];

  };
}
