{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.programs.terminal.tools.fzf;
  catppuccin = import ../../../theme/catppuccin.nix;
in
{
  options.khanelinix.programs.terminal.tools.fzf = {
    enable = mkBoolOpt false "Whether or not to enable fzf.";
  };

  config = mkIf cfg.enable {
    programs.fzf = {
      enable = true;
      package = pkgs.fzf;

      colors = {
        "preview-bg" = "-1";
        "gutter" = "-1";
        "bg" = "-1";
        "bg+" = "-1";
        "fg" = "${catppuccin.colors.surface2.hex}";
        "fg+" = "${catppuccin.colors.rosewater.hex}";
        "hl" = "${catppuccin.colors.blue.hex}";
        "hl+" = "${catppuccin.colors.blue.hex}";
        "header" = "${catppuccin.colors.blue.hex}";
        "info" = "${catppuccin.colors.yellow.hex}";
        "pointer" = "${catppuccin.colors.teal.hex}";
        "marker" = "${catppuccin.colors.teal.hex}";
        "prompt" = "${catppuccin.colors.yellow.hex}";
        "spinner" = "${catppuccin.colors.teal.hex}";
        "preview-fg" = "${catppuccin.colors.blue.hex}";
      };

      defaultCommand = "${lib.getExe pkgs.fd} --type=f --hidden --exclude=.git";
      defaultOptions = [
        "--layout=reverse" # Top-first.
        "--exact" # Substring matching by default, `'`-quote for subsequence matching.
        "--bind=alt-p:toggle-preview,alt-a:select-all"
        "--multi"
        "--no-mouse"
        "--info=inline"

        # Style and widget layout
        "--ansi"
        "--with-nth=1.."
        "--pointer=' '"
        "--pointer=' '"
        "--header-first"
        "--border=rounded"
      ];

      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;

      tmux = {
        enableShellIntegration = true;
      };
    };
  };
}
