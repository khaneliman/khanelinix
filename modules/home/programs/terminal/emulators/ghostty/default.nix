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
        font-family = "MonaspiceNe Nerd Font";
        font-family-bold = "MonaspiceXe Nerd Font";
        font-family-italic = "MonaspiceRn Nerd Font";
        font-family-bold-italic = "MonaspiceKr Nerd Font";
        font-feature = "+ss01,+ss02,+ss03,+ss04,+ss05,+ss06,+ss07,+ss08,+ss09,+liga,+calt";

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
