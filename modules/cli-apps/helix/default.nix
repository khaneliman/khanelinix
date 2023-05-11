inputs @ {
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.cli-apps.helix;
in {
  options.khanelinix.cli-apps.helix = with lib.types; {
    enable = lib.mkEnableOption "helix";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      helix
    ];

    # environment.variables = {
    #   PAGER = "less";
    #   MANPAGER = "less";
    #   EDITOR = "helix";
    # };

    # khanelinix.home = {
    #   configFile = {
    #     "helix/".source = inputs.dotfiles.outPath + "/dots/shared/home/.config/helix";
    #   };

    #   extraOptions = {
    #     # Use helix for Git diffs.
    #     programs.zsh.shellAliases.vimdiff = "helix -d";
    #     programs.bash.shellAliases.vimdiff = "helix -d";
    #     programs.fish.shellAliases.vimdiff = "helix -d";
    #   };
    # };
  };
}
