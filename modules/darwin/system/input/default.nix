{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf mkMerge mkEnableOption;

  cfg = config.khanelinix.system.input;
in
{
  options.khanelinix.system.input = {
    enable = mkEnableOption "macOS input";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      system = {
        defaults = {
          # trackpad settings
          trackpad = {
            # silent clicking = 0, default = 1
            ActuationStrength = 0;
            # enable tap to click
            Clicking = true;
            # Enable tap to drag
            # Dragging = true;
            # firmness level, 0 = lightest, 2 = heaviest
            FirstClickThreshold = 1;
            # firmness level for force touch
            SecondClickThreshold = 1;
            # don't allow positional right click
            TrackpadRightClick = true;
            # three finger drag
            TrackpadThreeFingerDrag = true;
          };

          ".GlobalPreferences" = {
            "com.apple.mouse.scaling" = 1.0;
          };

          NSGlobalDomain = {
            AppleKeyboardUIMode = 3;
            ApplePressAndHoldEnabled = false;

            KeyRepeat = 1;
            InitialKeyRepeat = 10;

            NSAutomaticCapitalizationEnabled = false;
            NSAutomaticDashSubstitutionEnabled = false;
            NSAutomaticQuoteSubstitutionEnabled = false;
            NSAutomaticPeriodSubstitutionEnabled = false;
            NSAutomaticSpellingCorrectionEnabled = false;
          };
        };
      };
    }
  ]);
}
