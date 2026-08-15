{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;

  cfg = config.khanelinix.programs.graphical.apps.codex-desktop;
  codexHome = config.home.sessionVariables.CODEX_HOME or "${config.home.homeDirectory}/.codex";
  waylandSupport = config.khanelinix.programs.graphical.addons.electron-support.enable or false;
in
{
  options.khanelinix.programs.graphical.apps.codex-desktop = {
    enable = mkEnableOption "Codex desktop integration";
  };

  config = lib.mkMerge [
    (mkIf cfg.enable {

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

      # Codex's durable SSH app-server daemon resolves its executable through
      # this fixed installer path. Keep that path on the Nix-managed CLI so a
      # dropped Remote Control websocket can restart without an orphan server.
      # TODO: Upstream a daemon executable override for package-managed installs,
      # then remove this standalone-layout compatibility link.
      xdg.configFile."codex/packages/standalone/current/codex" = lib.mkIf isLinux {
        source = lib.getExe pkgs.codex;
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
    })

    # Dock apps inherit launchd's environment instead of Home Manager's shell
    # startup files. Mirror CODEX_HOME and point the app at the patched CLI so
    # an explicit V1 setting wins over V2 model metadata. Restart the app after
    # activation to inherit these values.
    (mkIf isDarwin {
      home.activation.codexDesktopEnvironment = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        if cfg.enable then
          ''
            run /bin/launchctl setenv CODEX_HOME ${lib.escapeShellArg codexHome}
            run /bin/launchctl setenv CODEX_CLI_PATH ${lib.escapeShellArg (lib.getExe pkgs.codex)}
          ''
        else
          ''
            run /bin/launchctl unsetenv CODEX_HOME
            run /bin/launchctl unsetenv CODEX_CLI_PATH
          ''
      );
    })
  ];
}
