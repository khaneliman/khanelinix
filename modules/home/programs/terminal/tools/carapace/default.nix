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
      carapace =
        lib.khanelinix.shellIntegrations config [
          "bash"
          "fish"
          "nushell"
        ]
        // {
          # Carapace documentation
          # See: https://carapace-sh.github.io/carapace-bin/
          enable = true;

          # Prefer fzf-tab plugin
          enableZshIntegration = false;

          # Wrapping the binary reaches every shell integration; exporting from
          # zsh init only covered interactive zsh, and zsh integration is off.
          environment.CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense";
          extraPackages = [ pkgs.inshellisense ];
        };

      zsh.initContent = /* Bash */ ''
        zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
        zstyle ':completion:*:warnings' format $'\e[2;37mNo matches for %d\e[m'
        zstyle ':completion:*:git:*' group-order 'main commands' 'alias commands' 'external commands'
      '';
    };
  };
}
