{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.cli-apps.tmux;
  configFiles = lib.snowfall.fs.get-files ./config;

  plugins = [ ]
    ++ (with pkgs.tmuxPlugins; [
    continuum
    tmux-fzf
    vim-tmux-navigator
    {
      plugin = catppuccin;
      extraConfig = ''
        set -g @catppuccin_flavour 'macchiato'
        set -g @catppuccin_host 'on'
        set -g @catppuccin_user 'on'
      '';
    }
  ]);
in
{
  options.khanelinix.cli-apps.tmux = with types;
    {
      enable = mkBoolOpt false "Whether or not to enable tmux.";
    };

  config = mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      aggressiveResize = true;
      baseIndex = 1;
      clock24 = false;
      historyLimit = 2000;
      keyMode = "vi";
      mouse = true;
      newSession = true;
      prefix = "C-a";
      sensibleOnTop = true;
      terminal = "xterm-kitty";
      extraConfig =
        builtins.concatStringsSep "\n"
          (builtins.map lib.strings.fileContents configFiles);

      inherit plugins;
    };
  };
}
