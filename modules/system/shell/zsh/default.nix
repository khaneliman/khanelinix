{ options
, config
, lib
, pkgs
, inputs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.system.shell.zsh;
in
{
  options.khanelinix.system.shell.zsh = with types; {
    enable = mkBoolOpt false "Whether to enable zsh.";
  };

  config = mkIf cfg.enable {
    programs.zsh = {
      enable = true;
      # interactiveShellInit = ''
      #   source ${dotfiles.outPath}/dots/shared/home/.config/zsh/zshrc
      # '';
    };

    khanelinix.home = {
      file = with inputs; {
        ".zshrc".source = dotfiles.outPath + "/dots/shared/home/.zshrc";
        ".zshenv".source = dotfiles.outPath + "/dots/shared/home/.zshenv";
        ".p10k.zsh".source = dotfiles.outPath + "/dots/shared/home/.p10k.zsh";
        ".aliases".source = dotfiles.outPath + "/dots/shared/home/.aliases";
        ".functions".source = dotfiles.outPath + "/dots/shared/home/.functions";
      };
    };
  };
}
