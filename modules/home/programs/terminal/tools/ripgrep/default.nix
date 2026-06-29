{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) getExe mkForce mkIf;

  cfg = config.khanelinix.programs.terminal.tools.ripgrep;
in
{
  options.khanelinix.programs.terminal.tools.ripgrep = {
    enable = lib.mkEnableOption "ripgrep";
  };

  config = mkIf cfg.enable {
    programs.ripgrep = {
      # Ripgrep documentation
      # See: https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md#configuration-file
      enable = true;
      package = pkgs.ripgrep;

      arguments = [
        # --max-columns truncates long matches with a preview marker. Fine when
        # reading output interactively, but it mangles results when rg is piped
        # into scripts or tools that parse its output as data. Re-enable for
        # interactive use.
        # "--max-columns=150"
        # "--max-columns-preview"

        # ignore git files
        "--glob=!.git/*"

        "--smart-case"
      ];
    };

    home.shellAliases = {
      grep = mkForce (getExe config.programs.ripgrep.package);
    };
  };
}
