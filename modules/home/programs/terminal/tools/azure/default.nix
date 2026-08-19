{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.azure;
  active = cfg.enable || cfg.developmentEnable || cfg.devOpsEnable;
  azureCli =
    if cfg.devOpsEnable then
      pkgs.azure-cli.withExtensions [ pkgs.azure-cli-extensions.azure-devops ]
    else
      pkgs.azure-cli;
in
{
  options.khanelinix.programs.terminal.tools.azure = {
    enable = lib.mkEnableOption "Azure CLI";
    developmentEnable = lib.mkEnableOption "Azure development utilities";
    devOpsEnable = lib.mkEnableOption "Azure DevOps CLI commands";
  };

  config = mkIf active {
    # Azure CLI documentation
    # See: https://learn.microsoft.com/en-us/cli/azure/
    home.packages = [
      azureCli
    ]
    ++ lib.optionals cfg.developmentEnable [
      pkgs.azure-functions-core-tools
      pkgs.azure-storage-azcopy
      pkgs.bicep
      # azure-dev is not available in the pinned nixpkgs.
    ]
    ++ lib.optionals (cfg.developmentEnable && pkgs.stdenv.hostPlatform.isLinux) [
      pkgs.azuredatastudio
    ];

    home.shellAliases = lib.mkIf cfg.devOpsEnable {
      azwi = "az boards work-item show --id";
      azwq = "az boards query --wiql";
    };
  };
}
