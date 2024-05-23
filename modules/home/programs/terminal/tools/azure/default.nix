{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.terminal.tools.azure;
in
{
  options.${namespace}.programs.terminal.tools.azure = {
    enable = mkBoolOpt false "Whether or not to enable common Azure utilities.";
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        azure-functions-core-tools
        azure-storage-azcopy
        azuredatastudio
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [ azure-cli ];
  };
}
