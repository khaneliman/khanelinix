{
  config,
  lib,
  ...
}:
let
  cfg = config.khanelinix.theme.tokyonight;

  tokyonight = import ./colors.nix;
  colors = tokyonight.getVariant cfg.variant;
in
{
  config = lib.mkIf cfg.enable {
    programs.oh-my-posh.settings.palette = {
      osBg = colors.bg_dark;
      osFg = colors.fg;
      leading = colors.comment;
      line = colors.comment;

      pathBg = colors.blue;
      pathFg = colors.bg;

      gitBg = colors.green;
      gitFg = colors.bg;
      gitDirtyBg = colors.yellow;
      gitDivergedBg = colors.orange;
      gitAheadBg = colors.cyan;
      gitBehindBg = colors.green;

      filler = colors.bg_highlight;

      nodeBg = colors.green;
      nodeFg = colors.fg;
      goBg = colors.cyan;
      goFg = colors.bg;
      juliaBg = colors.blue;
      juliaFg = colors.bg;
      pythonBg = colors.yellow;
      pythonFg = colors.bg;
      rubyBg = colors.red;
      rubyFg = colors.fg;
      azfuncBg = colors.orange;
      azfuncFg = colors.fg;

      awsFg = colors.fg;
      awsDefaultBg = colors.yellow;
      awsJanBg = colors.red;

      rootBg = colors.yellow;
      rootFg = colors.bg;

      executionBg = colors.yellow;
      executionFg = colors.bg;

      exitBg = colors.bg_dark;
      exitFg = colors.green;
      exitErrFg = colors.yellow;
      exitErrBg = colors.red;

      timeBg = colors.fg;
      timeFg = colors.bg;

      transient = colors.green;
      transientError = colors.red;
      secondary = colors.green;

      tooltipGit = colors.green;
      tooltipAws = colors.orange;
    };
  };
}
