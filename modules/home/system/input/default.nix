{
  config,
  lib,
  osConfig ? { },
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.khanelinix.system.input;
  karabinerEnabled = osConfig.services.karabiner-elements.enable or false;
in
{
  imports = [
    ./karabiner.nix
  ];

  options.khanelinix.system.input = {
    enable = mkEnableOption "macOS input";
    notificationCenterRightEdgeSwipe = mkOption {
      type = types.nullOr (
        types.enum [
          0
          3
        ]
      );
      default = 0;
      description = "Two-finger swipe from the right edge on the trackpad: 0 disables it, 3 opens Notification Center.";
    };
  };

  config = mkIf cfg.enable {
    services.macos-remap-keys = mkIf (!karabinerEnabled) {
      enable = true;
      keyboard = {
        Capslock = "Escape";
      };
    };

    home.activation.notificationCenterRightEdgeSwipe =
      mkIf (pkgs.stdenv.hostPlatform.isDarwin && cfg.notificationCenterRightEdgeSwipe != null)
        (
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            echo >&2 "Setting Notification Center right-edge swipe gesture..."
            $DRY_RUN_CMD /usr/bin/defaults write com.apple.AppleMultitouchTrackpad \
              TrackpadTwoFingerFromRightEdgeSwipeGesture -int ${toString cfg.notificationCenterRightEdgeSwipe}
            $DRY_RUN_CMD /usr/bin/defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad \
              TrackpadTwoFingerFromRightEdgeSwipeGesture -int ${toString cfg.notificationCenterRightEdgeSwipe}
            $DRY_RUN_CMD /usr/bin/defaults -currentHost write NSGlobalDomain \
              com.apple.trackpad.twoFingerFromRightEdgeSwipeGesture -int ${toString cfg.notificationCenterRightEdgeSwipe}
            $DRY_RUN_CMD /usr/bin/killall cfprefsd >/dev/null 2>&1 || true
          ''
        );
  };
}
