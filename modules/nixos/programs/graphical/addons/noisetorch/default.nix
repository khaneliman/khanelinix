{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    literalExpression
    types
    ;

  cfg = config.${namespace}.programs.graphical.addons.noisetorch;
in
{
  options.${namespace}.programs.graphical.addons.noisetorch = {
    enable = mkEnableOption "noisetorch service";
    package = mkOption {
      type = types.package;
      default = pkgs.noisetorch;
      defaultText = literalExpression "pkgs.noisetorch";
      description = "Which package to use for noisetorch";
    };
    threshold = mkOption {
      type = types.int;
      default = -1;
      description = "Voice activation threshold (default -1)";
    };
    device = mkOption {
      type = types.str;
      description = "Use the specified source/sink device ID";
    };
    deviceUnit = mkOption {
      type = types.str;
      description = "Systemd device unit which is providing the audio device";
    };
  };

  config = mkIf cfg.enable {
    programs.noisetorch = {
      enable = true;

      inherit (cfg) package;
    };
  };
}
