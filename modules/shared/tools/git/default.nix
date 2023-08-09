{ options
, config
, pkgs
, lib
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.tools.git;
in
{
  options.khanelinix.tools.git = with types; {
    enable = mkBoolOpt false "Whether or not to install and configure git.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      bfg-repo-cleaner
      gh
      git
      git-crypt
      git-filter-repo
      git-lfs
      gitflow
      gitleaks
      gitlint
      lazygit
    ];
  };
}
