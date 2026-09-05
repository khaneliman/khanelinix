{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.carapace;
in
{
  options.khanelinix.programs.terminal.tools.carapace = {
    enable = lib.mkEnableOption "carapace";
  };

  config = mkIf cfg.enable {
    programs = {
      carapace = {
        # Carapace documentation
        # See: https://carapace-sh.github.io/carapace-bin/
        enable = true;

        enableBashIntegration = true;
        enableFishIntegration = true;
        # Prefer fzf-tab plugin
        enableZshIntegration = false;
        enableNushellIntegration = true;

        # Wrapping the binary reaches every shell integration; exporting from
        # zsh init only covered interactive zsh, and zsh integration is off.
        environment.CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense";
        extraPackages = [ pkgs.inshellisense ];
      };

      zsh.initContent = /* Bash */ ''
        zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
        zstyle ':completion:*:git:*' group-order 'main commands' 'alias commands' 'external commands'
      '';
    };
  };
}
