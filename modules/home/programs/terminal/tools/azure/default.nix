{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.programs.terminal.tools.azure;
in
{
  options.khanelinix.programs.terminal.tools.azure = {
    enable = mkBoolOpt false "Whether or not to enable common Azure utilities.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      azure-cli
      azure-functions-core-tools
      azure-storage-azcopy
      azuredatastudio
    ];
  };
}
