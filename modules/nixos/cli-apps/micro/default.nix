inputs @ { options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.cli-apps.micro;
in
{
  options.khanelinix.cli-apps.micro = with lib.types; {
    enable = lib.mkEnableOption "micro";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      micro
    ];

    environment.variables = {
      PAGER = "less";
      MANPAGER = "less";
      NPM_CONFIG_PREFIX = "$HOME/.npm-global";
      EDITOR = "micro";
    };

    khanelinix.home = {
      configFile = with inputs; {
        "micro/".source = dotfiles.outPath + "/dots/shared/home/.config/micro";
      };

      extraOptions = {
        # Use micro for Git diffs.
        programs.zsh.shellAliases.vimdiff = "micro -d";
        programs.bash.shellAliases.vimdiff = "micro -d";
        programs.fish.shellAliases.vimdiff = "micro -d";
      };
    };
  };
}
