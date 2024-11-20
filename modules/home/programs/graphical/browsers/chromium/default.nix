{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.programs.graphical.browsers.chromium;
in
{
  options.khanelinix.programs.graphical.browsers.chromium = {
    enable = mkBoolOpt false "Whether or not to enable chromium.";
  };

  config = mkIf cfg.enable {

    programs.chromium = {
      enable = true;

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
