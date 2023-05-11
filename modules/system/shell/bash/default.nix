{ options
, config
, lib
, pkgs
, inputs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.system.shell.bash;
in
{
  options.khanelinix.system.shell.bash = with types; {
    enable = mkBoolOpt false "Whether to enable bash.";
  };

  config = mkIf cfg.enable {
    # programs.bash = {
    #   enable = true;
    #   # interactiveShellInit = ''
    #   #   source ${dotfiles.outPath}/dots/shared/home/.config/bash/bashrc
    #   # '';
    # };

    khanelinix.home = {
      file = with inputs;
        {
          ".bashrc".source = dotfiles.outPath + "/dots/shared/home/.bashrc";
          ".bashenv".source = dotfiles.outPath + "/dots/shared/home/.bashenv";
          ".aliases".source = dotfiles.outPath + "/dots/shared/home/.aliases";
          ".functions".source = dotfiles.outPath + "/dots/shared/home/.functions";
        };
    };
  };
}
