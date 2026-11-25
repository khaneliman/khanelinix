{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.khanelinix.programs.graphical.wms.hyprland;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      settings = {
        on =
          let
            ##
            # ░█░█░█▀█░█▀▄░█░█░█▀▀░█▀█░█▀█░█▀▀░█▀▀░░░█▀▀░█▀█░█▀█░█▀▀░▀█▀░█▀▀
            # ░█▄█░█░█░█▀▄░█▀▄░▀▀█░█▀▀░█▀█░█░░░█▀▀░░░█░░░█░█░█░█░█▀▀░░█░░█░█
            # ░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀▀░▀░░░▀░▀░▀▀▀░▀▀▀░░░▀▀▀░▀▀▀░▀░▀░▀░░░▀▀▀░▀▀▀
            ##

            # Command to run when the workspace is created without windows.
            emptyWorkspaceCommands = {
              # Code
              "3" = "kitty zellij";
              # Gaming
              "4" = "steam";
              # Messaging
              "5" = "discord";
              # Mail
              "6" = "thunderbird";

              "special:scratchpad" = "kitty";
            };
          in
          [
            {
              _args = [
                "workspace.created"
                (lib.generators.mkLuaInline ''
                  (function()
                    local commands = ${lib.generators.toLua { } emptyWorkspaceCommands}

                    return function(workspace)
                      local command = commands[workspace.addressable_name]
                      if command and workspace.is_empty then
                        -- "silent" keeps a slow-starting app from switching back
                        -- to its workspace once focus has moved elsewhere, which
                        -- matters at login when every persistent workspace is
                        -- created at once. Hyprland ignores the rule when the
                        -- workspace is still the focused one, so the window
                        -- takes focus as usual there.
                        hl.exec_cmd(command, { workspace = workspace.addressable_name .. " silent" })
                      end
                    end
                  end)()
                '')
              ];
            }
          ];

        workspace_rule = lib.optionals cfg.smartGaps.enable [
          # Smart gaps: remove gaps when a normal workspace has one tiled window or one fullscreen window.
          {
            workspace = "w[tv1]s[false]";
            gaps_in = 0;
            gaps_out = 0;
          }
          {
            workspace = "f[1]s[false]";
            gaps_in = 0;
            gaps_out = 0;
          }
        ];

        window_rule = lib.mkIf cfg.smartGaps.enable [
          {
            match.float = false;
            match.workspace = "w[tv1]s[false]";
            border_size = 0;
            rounding = 0;
          }
          {
            match.float = false;
            match.workspace = "f[1]s[false]";
            border_size = 0;
            rounding = 0;
          }
        ];
      };
    };
  };
}
