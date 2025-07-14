{
  config,
  lib,

  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.graphical.browsers.chromium;
in
{
  options.khanelinix.programs.graphical.browsers.chromium = {
    enable = lib.mkEnableOption "chromium";
  };

  config = mkIf cfg.enable {

    programs.chromium = {
      enable = true;
      package = mkIf pkgs.stdenv.hostPlatform.isDarwin null;

      # extensions = with pkgs.chromium-extensions; [
      #   catppuccin.catppuccin-vsc
      #   eamodio.gitlens
      #   formulahendry.auto-close-tag
      #   formulahendry.auto-rename-tag
      #   github.chromium-github-actions
      #   github.chromium-pull-request-github
      #   gruntfuggly.todo-tree
      #   mkhl.direnv
      #   chromium-icons-team.vscode-icons
      #   wakatime.chromium-wakatime
      # ];
    };
  };
}
