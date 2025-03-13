{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.${namespace}.system.input;
in
{
  options.${namespace}.system.input = {
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
