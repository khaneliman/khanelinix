{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.apps.vscode;
in
{
  options.khanelinix.apps.vscode = {
    enable = mkBoolOpt false "Whether or not to enable vscode.";
  };
  # TODO: remove module

  config =
    mkIf cfg.enable {
      environment.systemPackages = with pkgs; [ vscode ];
    };
}
