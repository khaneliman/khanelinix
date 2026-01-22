{
  config,
  lib,

  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.emulators.ghostty;

in
{
  options.khanelinix.programs.terminal.emulators.ghostty = {
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

      settings =
        let
          monaspaceKrypton =
            if pkgs.stdenv.hostPlatform.isDarwin then "Monaspace Krypton NF" else "MonaspaceKrypton NF";
          monaspaceNeon =
            if pkgs.stdenv.hostPlatform.isDarwin then "Monaspace Neon NF" else "MonaspaceNeon NF";
          monaspaceRadon =
            if pkgs.stdenv.hostPlatform.isDarwin then "Monaspace Radon NF" else "MonaspaceRadon NF";
          monaspaceXenon =
            if pkgs.stdenv.hostPlatform.isDarwin then "Monaspace Xenon NF" else "MonaspaceXenon NF";
        in
        {
          adw-toolbar-style = "flat";

          background-opacity = lib.mkDefault 0.8;

          clipboard-trim-trailing-spaces = true;
          copy-on-select = "clipboard";

          focus-follows-mouse = true;

          font-size = lib.mkDefault 13;
          font-family = lib.mkForce monaspaceNeon;
          font-family-bold = lib.mkForce monaspaceXenon;
          font-family-italic = lib.mkForce monaspaceRadon;
          font-family-bold-italic = lib.mkForce monaspaceKrypton;
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
