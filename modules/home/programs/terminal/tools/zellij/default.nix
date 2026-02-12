{
  config,
  lib,

  osConfig ? { },
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.programs.terminal.tools.zellij;
in
{
  imports = [
    ./keybinds.nix
    ./layouts/dev.nix
    ./layouts/system.nix
  ];

  options.khanelinix.programs.terminal.tools.zellij = {
    enable = lib.mkEnableOption "zellij";
  };

  config = lib.mkIf cfg.enable {
    programs =
      let
        zns = "zellij -s $(basename $(pwd)) options --default-cwd $(pwd)";
        zas = "zellij a $(basename $(pwd))";
        zds = "zellij delete-session $(basename $(pwd))";
        zo = /* Bash */ ''
          session_name=$(basename "$(pwd)")

          zellij attach --create "$session_name" options --default-cwd "$(pwd)"
        '';
      in
      {
        bash.shellAliases = {
          inherit
            zas
            zds
            zns
            zo
            ;
        };

        zsh.shellAliases = {
          inherit
            zas
            zds
            zns
            zo
            ;
        };

        zellij = {
          enable = true;
          package = pkgs.zellij.overrideAttrs (_oldAttrs: {
            patches = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
              (pkgs.fetchpatch2 {
                url = "https://github.com/zellij-org/zellij/commit/60acd439985339e518f090821c0e4eb366ce6014.patch?full_index=1";
                hash = "sha256-pCFDEbgceNzZAjxSXme/nQ4iQc8qNw2IOMtec16cr8k=";
              })
            ];
          });

          settings = {
            # clipboard provider
            copy_command =
              if pkgs.stdenv.hostPlatform.isLinux && (osConfig.khanelinix.archetypes.wsl.enable or false) then
                "clip.exe"
              else if pkgs.stdenv.hostPlatform.isLinux then
                "wl-copy"
              else if pkgs.stdenv.hostPlatform.isDarwin then
                "pbcopy"
              else
                "";

            auto_layouts = true;

            default_layout = "dev";
            default_mode = "locked";
            support_kitty_keyboard_protocol = true;

            on_force_close = "quit";
            pane_frames = true;
            pane_viewport_serialization = true;
            scrollback_lines_to_serialize = 1000;
            session_serialization = true;
            post_command_discovery_hook = ''
              case "$RESURRECT_COMMAND" in
                /nix/store/*/bin/*)
                  printf '%s\n' "''${RESURRECT_COMMAND#*/bin/}"
                  ;;
                *)
                  printf '%s\n' "$RESURRECT_COMMAND"
                  ;;
              esac
            '';

            ui.pane_frames = {
              rounded_corners = true;
              hide_session_name = true;
            };

            # load internal plugins from built-in paths
            plugins = {
              tab-bar.path = "tab-bar";
              status-bar.path = "status-bar";
              strider.path = "strider";
              compact-bar.path = "compact-bar";
            };

            theme = lib.mkDefault "catppuccin-macchiato";
          };
        };
      };
  };
}
