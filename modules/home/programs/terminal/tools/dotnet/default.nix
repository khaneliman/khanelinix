{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.dotnet;
  # sdk_11_0 stays out until it leaves preview; the pinned attribute is a
  # preview build. Add stable SDKs to this list as projects need them.
  dotnet = pkgs.dotnetCorePackages.combinePackages [
    pkgs.dotnetCorePackages.sdk_10_0
  ];
in
{
  options.khanelinix.programs.terminal.tools.dotnet = {
    enable = lib.mkEnableOption ".NET SDK support";
  };

  config = mkIf cfg.enable {
    home = {
      packages = [ dotnet ];
      sessionPath = [ "${config.home.homeDirectory}/.dotnet/tools" ];
      sessionVariables = {
        DOTNET_CLI_TELEMETRY_OPTOUT = "1";
        DOTNET_ROOT = "${dotnet}/share/dotnet";
      };
    };
  };
}
