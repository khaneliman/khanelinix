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

    # Upstream module selects the feature set that its CI builds and pushes
    # to Cachix. Behavior settings flow through `programs.codex.settings`,
    # which the desktop app shares with the CLI.
    programs.codexDesktopLinux = lib.optionalAttrs isLinux {
      enable = true;
      linuxFeatures = [
        "appshots"
        "node-repl-reaper"
        "persistent-status-panel"
        "shallow-repository-watches"
      ];
    };

    programs.codex.settings.desktop = {
      appearanceDiffMarkerStyle = "color";
      followUpQueueMode = "steer";
      "git-always-force-push" = false;
      "git-branch-prefix" = "";
      "notifications-turn-mode" = "always";
      reviewDelivery = "inline";
      usePointerCursors = false;
    };

    # Keep GPU compositing enabled on native Wayland. The Linux launcher
    # otherwise adds --disable-gpu-compositing as a compatibility fallback.
    home.sessionVariables = lib.mkMerge [
      # The upstream module no longer owns CODEX_CLI_PATH. Keep the desktop
      # app on the same patched CLI as the terminal integration.
      (mkIf isLinux {
        CODEX_CLI_PATH = lib.getExe pkgs.codex;
      })
      (mkIf waylandSupport {
        CODEX_LINUX_RENDERING_MODE = "wayland-gpu";
      })
    ];

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
