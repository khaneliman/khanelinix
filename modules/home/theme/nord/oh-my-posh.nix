{
  config,
  lib,
  ...
}:
let
  cfg = config.khanelinix.theme.nord;
  nord = import ./colors.nix;
in
{
  config = lib.mkIf cfg.enable {
    programs.oh-my-posh.settings.palette = {
      osBg = nord.palette.nord9.hex;
      osFg = nord.palette.nord1.hex;
      leading = nord.palette.nord14.hex;
      line = nord.palette.nord14.hex;

      pathBg = nord.palette.nord4.hex;
      pathFg = nord.palette.nord0.hex;

      gitBg = nord.palette.nord3.hex;
      gitFg = nord.palette.nord4.hex;
      gitDirtyBg = nord.palette.nord13.hex;
      gitDivergedBg = nord.palette.nord12.hex;
      gitAheadBg = nord.palette.nord8.hex;
      gitBehindBg = nord.palette.nord14.hex;

      filler = nord.palette.nord2.hex;

      nodeBg = nord.palette.nord14.hex;
      nodeFg = nord.palette.nord1.hex;
      goBg = nord.palette.nord9.hex;
      goFg = nord.palette.nord1.hex;
      juliaBg = nord.palette.nord15.hex;
      juliaFg = nord.palette.nord1.hex;
      pythonBg = nord.palette.nord13.hex;
      pythonFg = nord.palette.nord1.hex;
      rubyBg = nord.palette.nord11.hex;
      rubyFg = nord.palette.nord1.hex;
      azfuncBg = nord.palette.nord9.hex;
      azfuncFg = nord.palette.nord1.hex;

      awsFg = nord.palette.nord1.hex;
      awsDefaultBg = nord.palette.nord13.hex;
      awsJanBg = nord.palette.nord11.hex;

      rootBg = nord.palette.nord13.hex;
      rootFg = nord.palette.nord1.hex;

      executionBg = nord.palette.nord13.hex;
      executionFg = nord.palette.nord1.hex;

      exitBg = nord.palette.nord1.hex;
      exitFg = nord.palette.nord14.hex;
      exitErrFg = nord.palette.nord13.hex;
      exitErrBg = nord.palette.nord11.hex;

      timeBg = nord.palette.nord9.hex;
      timeFg = nord.palette.nord1.hex;

      transient = nord.palette.nord14.hex;
      transientError = nord.palette.nord11.hex;
      secondary = nord.palette.nord9.hex;

      tooltipGit = nord.palette.nord14.hex;
      tooltipAws = nord.palette.nord12.hex;
    };
  };
}
