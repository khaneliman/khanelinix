{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.shells.powershell;
in
{
  options.khanelinix.programs.terminal.shells.powershell = {
    enable = lib.mkEnableOption "PowerShell";
  };

  config = mkIf cfg.enable {
    # Pinned nixpkgs does not expose PSScriptAnalyzer as a package. Install it
    # manually with `Install-Module PSScriptAnalyzer -Scope CurrentUser`.
    # The nixpkgs pwsh wrapper already opts out of telemetry.
    home.packages = [ pkgs.powershell ];
  };
}
