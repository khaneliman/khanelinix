{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.terminal.emulators.ghostty;

in
{
  options.${namespace}.programs.terminal.emulators.ghostty = {
    enable = mkBoolOpt false "Whether or not to enable ghostty.";
  };

  config = mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      package = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin pkgs.emptyDirectory;

      installBatSyntax = true;
      installVimSyntax = true;

      enableBashIntegration = true;
      enableFishIntegration = true;
      enableZshIntegration = true;

      settings = {
        background-opacity = 0.8;
        window-decoration = lib.mkIf pkgs.stdenv.hostPlatform.isLinux false;
        macos-titlebar-style = "hidden";
      };
    };
  };
}
