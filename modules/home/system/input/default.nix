{
  config,
  lib,
  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.khanelinix.system.input;
  karabinerEnabled = osConfig.services.karabiner-elements.enable or false;
in
{
  imports = [
    ./karabiner.nix
  ];

  options.khanelinix.system.input = {
    enable = mkEnableOption "macOS input";
  };

  config = mkIf cfg.enable {
    services.macos-remap-keys = mkIf (!karabinerEnabled) {
      enable = true;
      keyboard = {
        Capslock = "Escape";
      };
    };
  };
}
