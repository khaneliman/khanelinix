{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.programs.terminal.emulators.ghostty;

in
{
  options.${namespace}.programs.terminal.emulators.ghostty = {
    enable = lib.mkEnableOption "ghostty";
  };

  config = mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      package = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin null;

      installBatSyntax = pkgs.stdenv.hostPlatform.isLinux;
      installVimSyntax = pkgs.stdenv.hostPlatform.isLinux;

      enableBashIntegration = true;
      enableFishIntegration = true;
      enableZshIntegration = true;

      settings = {
        adw-toolbar-style = "flat";

        background-opacity = 0.8;

        clipboard-trim-trailing-spaces = true;
        copy-on-select = "clipboard";

        focus-follows-mouse = true;

        font-size = 13;
        font-family = if pkgs.stdenv.hostPlatform.isDarwin then "Monaspace Neon Var" else "MonaspaceNeon";
        font-family-bold =
          if pkgs.stdenv.hostPlatform.isDarwin then "Monaspace Xenon Var" else "MonaspaceXenon";
        font-family-italic =
          if pkgs.stdenv.hostPlatform.isDarwin then "Monaspace Radon Var" else "MonaspaceRadon";
        font-family-bold-italic =
          if pkgs.stdenv.hostPlatform.isDarwin then "Monaspace Krypton Var" else "MonaspaceKrypton";
        font-feature = "+ss01,+ss02,+ss03,+ss04,+ss05,+ss06,+ss07,+ss08,+ss09,+ss10,+liga,+dlig,+calt";

        # NOTE: Different methods of using cgroups for every surface.
        # linux-cgroup = "always";
        gtk-single-instance = false;

        # Breaks tab functionality, but tab functionality is broken with yabai
        macos-titlebar-style = "hidden";
        macos-option-as-alt = true;

        quit-after-last-window-closed = true;

        # Disables some functionality available through window
        # But, doesn't fit theme of a clean WM with its GTK interface
        window-decoration = lib.mkIf pkgs.stdenv.hostPlatform.isLinux false;
      };
    };
  };
}
