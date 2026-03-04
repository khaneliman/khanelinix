{
  config,
  lib,
  ...
}:
let
  cfg = config.khanelinix.theme.catppuccin;

  catppuccin = import (lib.getFile "modules/home/theme/catppuccin/colors.nix");
in
{
  config = lib.mkIf cfg.enable {
    programs.oh-my-posh.settings.palette = {
      osBg = catppuccin.colors.surface0.hex;
      osFg = catppuccin.colors.text.hex;
      leading = catppuccin.colors.overlay0.hex;
      line = catppuccin.colors.overlay0.hex;

      pathBg = catppuccin.colors.blue.hex;
      pathFg = catppuccin.colors.base.hex;

      gitBg = catppuccin.colors.green.hex;
      gitFg = catppuccin.colors.base.hex;
      gitDirtyBg = catppuccin.colors.yellow.hex;
      gitDivergedBg = catppuccin.colors.peach.hex;
      gitAheadBg = catppuccin.colors.sky.hex;
      gitBehindBg = catppuccin.colors.green.hex;

      filler = catppuccin.colors.surface1.hex;

      nodeBg = catppuccin.colors.green.hex;
      nodeFg = catppuccin.colors.text.hex;
      goBg = catppuccin.colors.sky.hex;
      goFg = catppuccin.colors.base.hex;
      juliaBg = catppuccin.colors.blue.hex;
      juliaFg = catppuccin.colors.base.hex;
      pythonBg = catppuccin.colors.yellow.hex;
      pythonFg = catppuccin.colors.base.hex;
      rubyBg = catppuccin.colors.red.hex;
      rubyFg = catppuccin.colors.text.hex;
      azfuncBg = catppuccin.colors.peach.hex;
      azfuncFg = catppuccin.colors.text.hex;

      awsFg = catppuccin.colors.text.hex;
      awsDefaultBg = catppuccin.colors.yellow.hex;
      awsJanBg = catppuccin.colors.red.hex;

      rootBg = catppuccin.colors.yellow.hex;
      rootFg = catppuccin.colors.base.hex;

      executionBg = catppuccin.colors.yellow.hex;
      executionFg = catppuccin.colors.base.hex;

      exitBg = catppuccin.colors.surface0.hex;
      exitFg = catppuccin.colors.green.hex;
      exitErrFg = catppuccin.colors.yellow.hex;
      exitErrBg = catppuccin.colors.red.hex;

      timeBg = catppuccin.colors.text.hex;
      timeFg = catppuccin.colors.base.hex;

      transient = catppuccin.colors.green.hex;
      transientError = catppuccin.colors.red.hex;
      secondary = catppuccin.colors.green.hex;

      tooltipGit = catppuccin.colors.green.hex;
      tooltipAws = catppuccin.colors.peach.hex;
    };
  };
}
