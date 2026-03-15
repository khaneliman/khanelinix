{
  config,
  lib,

  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.emulators.ghostty;
  fontCfg = config.khanelinix.fonts;

in
{
  options.khanelinix.programs.terminal.emulators.ghostty = {
    enable = lib.mkEnableOption "ghostty";
  };

  config = mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      package = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin pkgs.ghostty-bin;

      installBatSyntax = pkgs.stdenv.hostPlatform.isLinux;
      installVimSyntax = pkgs.stdenv.hostPlatform.isLinux;

      enableBashIntegration = true;
      enableFishIntegration = true;
      enableZshIntegration = true;

      # Ghostty configuration
      # See: https://ghostty.org/docs/config/reference
      settings =
        let
          monaspaceKrypton = fontCfg.monaspace.families.krypton;
          monaspaceNeon = fontCfg.monaspace.families.neon;
          monaspaceRadon = fontCfg.monaspace.families.radon;
          monaspaceXenon = fontCfg.monaspace.families.xenon;
        in
        {
          adw-toolbar-style = "flat";
          background-blur-radius = 20;
          background-opacity = lib.mkDefault 0.8;
          clipboard-trim-trailing-spaces = true;
          copy-on-select = "clipboard";
          focus-follows-mouse = true;
          font-family = lib.mkForce monaspaceNeon;
          font-family-bold = lib.mkForce monaspaceXenon;
          font-family-bold-italic = lib.mkForce monaspaceKrypton;
          font-family-italic = lib.mkForce monaspaceRadon;
          font-feature = "+ss01,+ss02,+ss03,+ss04,+ss05,+ss06,+ss07,+ss08,+ss09,+ss10,+liga,+dlig,+calt";
          font-size = lib.mkDefault 13;

          # NOTE: Different methods of using cgroups for every surface.
          # linux-cgroup = "always";
          gtk-single-instance = false;

          macos-auto-secure-input = true;
          # macos-hidden = "always";
          macos-option-as-alt = true;
          macos-secure-input-indication = true;
          macos-titlebar-style = "tabs";
          macos-icon-frame = lib.mkDefault "plastic";

          quit-after-last-window-closed = true;
          window-colorspace = "srgb";
          window-theme = "ghostty";
          # NOTE: Disables some functionality available through window
          # But, doesn't fit theme of a clean WM with its GTK interface
          window-decoration = lib.mkIf pkgs.stdenv.hostPlatform.isLinux false;
        };
    };
  };
}
