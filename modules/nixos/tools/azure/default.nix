{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.tools.azure;
in
{
  options.khanelinix.tools.azure = {
    enable =
      mkBoolOpt false "Whether or not to enable common Azure utilities.";
  };

  config = mkIf cfg.enable {

    environment.systemPackages = with pkgs; [
      azure-cli
      azure-functions-core-tools
      azure-storage-azcopy
      azuredatastudio
    ];
  };
}
