{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.tools.dotnet;
in {
  options.khanelinix.tools.dotnet = with types; {
    enable = mkBoolOpt false "Whether or not to enable dotnet.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      dotnet-sdk_7
      dotnet-runtime_7
    ];
  };
}
