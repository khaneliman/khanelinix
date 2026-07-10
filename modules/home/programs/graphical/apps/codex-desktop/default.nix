{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (pkgs.stdenv.hostPlatform) isLinux;

  cfg = config.khanelinix.programs.graphical.apps.codex-desktop;
  waylandSupport = config.khanelinix.programs.graphical.addons.electron-support.enable or false;
in
{
  options.khanelinix.programs.graphical.apps.codex-desktop = {
    enable = mkEnableOption "ChatGPT Desktop for Linux";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = isLinux;
        message = "ChatGPT Desktop is only available on Linux";
      }
    ];

    # Upstream module wraps the launcher with CODEX_CLI_PATH and selects the
    # feature set upstream CI builds and pushes to cachix. Behavior settings
    # (features, MCP servers, ...) flow through `programs.codex.settings`,
    # which the desktop app shares with the CLI.
    programs.codexDesktopLinux = {
      enable = true;
      cliPackage = pkgs.codex;
      linuxFeatures = [
        "appshots"
        "node-repl-reaper"
        "open-target-discovery"
        "persistent-status-panel"
      ];
    };

    # The launcher reads its own flags file instead of the generic
    # electron-flags.conf and only seeds a commented template when the file is
    # missing, so owning it declaratively is safe.
    xdg.configFile."codex-desktop/electron-flags.conf" = mkIf waylandSupport {
      text = ''
        --wayland
        --enable-features=WaylandWindowDecorations
        --enable-wayland-ime
        --wayland-text-input-version=1
      '';
    };
  };
}
