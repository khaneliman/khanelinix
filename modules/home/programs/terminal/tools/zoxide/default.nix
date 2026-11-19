{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.zoxide;
in
{
  options.khanelinix.programs.terminal.tools.zoxide = {
    enable = lib.mkEnableOption "zoxide";
  };

  config = mkIf cfg.enable {
    programs.zoxide =
      lib.khanelinix.shellIntegrations config [
        "bash"
        "fish"
        "nushell"
        "zsh"
      ]
      // {
        # Zoxide documentation
        # See: https://github.com/ajeetdsouza/zoxide
        enable = true;
        package = pkgs.zoxide;

        options = [ "--cmd cd" ];
      };
  };
}
