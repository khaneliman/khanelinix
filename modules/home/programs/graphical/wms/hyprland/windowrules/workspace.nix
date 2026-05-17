{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.graphical.wms.hyprland;

  firefoxClass = "^(?i:firefox|firefox-devedition)$";
  mediaTitle = "^(?i).*(Twitch|TNTdrama|YouTube|Bally Sports|Video Entertainment|Plex).*$";
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      settings = {
        # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
        window_rule = [
          #Browsers - Move all Firefox windows to workspace 2 by default
          {
            match.class = firefoxClass;
            workspace = "2";
          }
          # Secondary Monitor Media
          # Exception rule to override the above rule - Media sites go to workspace 1
          {
            match.class = firefoxClass;
            match.title = mediaTitle;
            workspace = "1";
          }

          {
            match.class = firefoxClass;
            match.title = "^(?i).*(hidden tabs - Workona).*$";
            workspace = "special:inactive";
          }
          # Code
          {
            match.class = "^(Code|neovide|GitHub Desktop|GitKraken|robloxstudiobeta.exe)$";
            workspace = "3";
          }
          # Gaming
          {
            match.class = "^(Steam|steam|steamwebhelper)$";
            workspace = "4 silent";
          }
          {
            match.class = "^(Steam|steam)$";
            match.title = "^(Steam|steam)$";
            workspace = "4 silent";
          }
          {
            match.class = "^(steam)$";
            no_initial_focus = true;
          }
          {
            match.class = "^(steam)$";
            focus_on_activate = false;
          }
          {
            match.class = "^(gamescope|steam_app).*";
            workspace = "4 silent";
          }
          {
            match.class = "^(heroic|lutris|org.vinegarhq.Sober)$";
            workspace = "4";
          }
          {
            match.class = "^(steam_app).*";
            workspace = "4";
          }
          {
            match.class = ".*(cemu|yuzu|Ryujinx|emulationstation|retroarch).*";
            workspace = "4";
          }
          {
            match.title = ".*(cemu|yuzu|Ryujinx|emulationstation|retroarch).*";
            workspace = "4";
          }
          # Messaging
          {
            match.class = "^(Slack|Caprine|org.telegram.desktop|discord|vesktop|zoom|Element|teams-for-linux)$";
            workspace = "5 silent";
          }
          # Mail
          {
            match.class = "^(thunderbird|Mailspring)$";
            workspace = "6 silent";
          }
          # Media
          {
            match.class = "^(mpv|vlc|mpdevil)$";
            workspace = "7";
          }
          {
            match.class = "^(Spotify|elisa)$";
            workspace = "7 silent";
          }
          {
            match.title = "^(Spotify|Spotify Free)$";
            workspace = "7 silent";
          }
          #Remote
          {
            match.class = "^(virt-manager|qemu|gnome-connections)$";
            workspace = "8 silent";
          }
          {
            match.class = "^(looking-glass-client)$";
            workspace = "8";
          }
          # Citrix
          {
            match.class = "^(selfservice|Wfica)$";
            workspace = "8";
          }
          {
            match.class = "^(Icasessionmgr)$";
            workspace = "8 silent";
          }
        ];

        on =
          let
            routeFirefoxWindows =
              allowDefaultRoute:
              lib.generators.mkLuaInline ''
                function()
                  for _, window in ipairs(hl.get_windows()) do
                    local class = string.lower(window.class or "")
                    if class == "firefox" or class == "firefox-devedition" then
                      local title = string.lower(window.title or "")
                      local target = "2"

                      if title:find("hidden tabs %- workona") then
                        target = "special:inactive"
                      elseif title:find("twitch") or title:find("tntdrama") or title:find("youtube") or title:find("bally sports") or title:find("video entertainment") or title:find("plex") then
                        target = "1"
                      end

                      local shouldRoute = true

                      if target == "2" and ${lib.boolToString (!allowDefaultRoute)} then
                        shouldRoute = false
                      end

                      if target ~= "2" and window.workspace ~= nil and window.workspace.name ~= "2" then
                        shouldRoute = false
                      end

                      if shouldRoute and (window.workspace == nil or window.workspace.name ~= target) then
                        hl.dispatch(hl.dsp.window.move({
                          workspace = target,
                          follow = false,
                          window = "address:" .. window.address,
                        }))
                      end
                    end
                  end
                end
              '';
          in
          lib.mkIf (config.wayland.windowManager.hyprland.configType == "lua") (
            lib.mkAfter [
              {
                _args = [
                  "window.open"
                  (routeFirefoxWindows true)
                ];
              }
              {
                _args = [
                  "window.title"
                  (routeFirefoxWindows false)
                ];
              }
            ]
          );
      };
    };
  };
}
