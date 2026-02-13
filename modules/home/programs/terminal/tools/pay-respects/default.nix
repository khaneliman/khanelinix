{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.pay-respects;
in
{
  options.khanelinix.programs.terminal.tools.pay-respects = {
    enable = lib.mkEnableOption "pay-respects";
  };

  config = mkIf cfg.enable {
    programs.pay-respects = {
      enable = true;

      enableBashIntegration = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;

      # Edit these directly here as you experiment with pay-respects behavior.
      options = [
        "--alias"
        "f"
        "--nocnf"
      ];

      rules = {
        _PR_GENERAL = {
          match_err = [
            {
              pattern = [ "permission denied" ];
              suggest = [
                "#[executable(sudo), !cmd_contains(sudo)]\nsudo {{command}}"
              ];
            }
          ];
        };

        cargo = {
          command = "cargo";
          match_err = [
            {
              pattern = [ "could not find `Cargo.toml`" ];
              suggest = [ "cargo init" ];
            }
          ];
        };

        git = {
          command = "git";
          match_err = [
            {
              pattern = [ "has no upstream branch" ];
              suggest = [ "git push --set-upstream origin $(git branch --show-current)" ];
            }
          ];
        };

        nix = {
          command = "nix";
          match_err = [
            {
              pattern = [ "does not provide attribute" ];
              suggest = [ "nix flake show" ];
            }
          ];
        };
      };
    };
  };
}
