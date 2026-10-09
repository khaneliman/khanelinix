{
  config,
  lib,
  ...
}:
let
  cfg = config.khanelinix.theme.nord;
  nord = import ./colors.nix;
  # nord11, nord12, and nord15 miss 4.5:1 against nord0 both as text and as
  # fills under nord0 text. These keep each OKLCH hue and chroma with
  # lightness solved to 4.6:1.
  red = "#e38189";
  orange = "#d58c74";
  purple = "#b993b2";
in
{
  config = lib.mkIf cfg.enable {
    programs.oh-my-posh.settings.palette = {
      osBg = nord.palette.nord9.hex;
      osFg = nord.palette.nord0.hex;
      leading = nord.palette.nord14.hex;
      line = nord.palette.nord14.hex;

      pathBg = nord.palette.nord4.hex;
      pathFg = nord.palette.nord0.hex;

      # One foreground covers every git state, so all fills stay light.
      gitBg = nord.palette.nord14.hex;
      gitFg = nord.palette.nord0.hex;
      gitDirtyBg = nord.palette.nord13.hex;
      gitDivergedBg = orange;
      gitAheadBg = nord.palette.nord8.hex;
      gitBehindBg = nord.palette.nord14.hex;

      filler = nord.palette.nord2.hex;

      nodeBg = nord.palette.nord14.hex;
      nodeFg = nord.palette.nord0.hex;
      goBg = nord.palette.nord9.hex;
      goFg = nord.palette.nord0.hex;
      juliaBg = purple;
      juliaFg = nord.palette.nord0.hex;
      pythonBg = nord.palette.nord13.hex;
      pythonFg = nord.palette.nord0.hex;
      rubyBg = red;
      rubyFg = nord.palette.nord0.hex;
      azfuncBg = nord.palette.nord9.hex;
      azfuncFg = nord.palette.nord0.hex;

      awsFg = nord.palette.nord0.hex;
      awsDefaultBg = nord.palette.nord13.hex;
      awsJanBg = red;

      rootBg = nord.palette.nord13.hex;
      rootFg = nord.palette.nord0.hex;

      executionBg = nord.palette.nord13.hex;
      executionFg = nord.palette.nord0.hex;

      exitBg = nord.palette.nord1.hex;
      exitFg = nord.palette.nord14.hex;
      exitErrFg = nord.palette.nord0.hex;
      exitErrBg = red;

      timeBg = nord.palette.nord9.hex;
      timeFg = nord.palette.nord0.hex;

      transient = nord.palette.nord14.hex;
      transientError = red;
      secondary = nord.palette.nord9.hex;

      tooltipGit = nord.palette.nord14.hex;
      tooltipAws = orange;
    };
  };
}
