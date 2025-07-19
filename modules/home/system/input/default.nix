{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.khanelinix.system.input;
in
{
  options.khanelinix.system.input = {
    enable = mkEnableOption "macOS input";
  };

  config = mkIf cfg.enable {
    services.macos-remap-keys = {
      enable = true;
      keyboard = {
        Capslock = "Escape";
      };
    };
  };
}
