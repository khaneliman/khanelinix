{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.programs.graphical.apps.hammerspoon;
in
{
  options.khanelinix.programs.graphical.apps.hammerspoon.enable =
    lib.mkEnableOption "Hammerspoon automation";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "Hammerspoon automation is only supported on Darwin.";
      }
    ];

    home = {
      file = {
        "Library/Application Support/Hammerspoon/init.lua".text =
          # lua
          ''
            hs.window.animationDuration = 0

            local hyper = { "cmd", "alt", "ctrl" }
            local meetingMode = false

            local function notify(title, text)
              hs.notify.new({ title = title, informativeText = text }):send()
            end

            local function focusedWindow()
              local window = hs.window.focusedWindow()
              if window == nil then
                notify("Hammerspoon", "No focused window")
                return nil
              end
              return window
            end

            local function moveFocused(unit)
              local window = focusedWindow()
              if window ~= nil then
                window:moveToUnit(unit)
              end
            end

            local function moveFocusedToNextScreen()
              local window = focusedWindow()
              if window ~= nil then
                window:moveToScreen(window:screen():next(), false, true)
              end
            end

            local function rescueWindows()
              local rescued = 0
              for _, window in ipairs(hs.window.visibleWindows()) do
                if window:isStandard() then
                  local frame = window:frame()
                  local screenFrame = window:screen():frame()
                  local offscreen = frame.x < screenFrame.x
                    or frame.y < screenFrame.y
                    or frame.x + frame.w > screenFrame.x + screenFrame.w
                    or frame.y + frame.h > screenFrame.y + screenFrame.h

                  if offscreen then
                    window:centerOnScreen()
                    rescued = rescued + 1
                  end
                end
              end
              notify("Window Rescue", tostring(rescued) .. " windows moved")
            end

            local function toggleInputMute()
              local device = hs.audiodevice.defaultInputDevice()
              if device == nil then
                notify("Mic", "No input device")
                return
              end

              local muted = not device:inputMuted()
              device:setInputMuted(muted)
              notify("Mic", muted and "muted" or "unmuted")
            end

            local function cycleOutputDevice()
              local devices = hs.audiodevice.allOutputDevices()
              if #devices == 0 then
                notify("Audio Output", "No output devices")
                return
              end

              table.sort(devices, function(left, right)
                return left:name() < right:name()
              end)

              local current = hs.audiodevice.defaultOutputDevice()
              local nextIndex = 1

              if current ~= nil then
                for index, device in ipairs(devices) do
                  if device:uid() == current:uid() then
                    nextIndex = (index % #devices) + 1
                    break
                  end
                end
              end

              local nextDevice = devices[nextIndex]
              nextDevice:setDefaultOutputDevice()
              notify("Audio Output", nextDevice:name())
            end

            local function toggleMeetingMode()
              meetingMode = not meetingMode
              hs.caffeinate.set("systemIdle", meetingMode, true)
              hs.caffeinate.set("displayIdle", meetingMode, true)

              hs.application.launchOrFocus("Fantastical")
              hs.application.launchOrFocus("Microsoft Teams")
              notify("Meeting Mode", meetingMode and "on" or "off")
            end

            hs.hotkey.bind(hyper, "Left", function()
              moveFocused(hs.layout.left50)
            end)
            hs.hotkey.bind(hyper, "Right", function()
              moveFocused(hs.layout.right50)
            end)
            hs.hotkey.bind(hyper, "Up", function()
              moveFocused(hs.layout.maximized)
            end)
            hs.hotkey.bind(hyper, "Down", function()
              moveFocused({ x = 0.16, y = 0.10, w = 0.68, h = 0.80 })
            end)
            hs.hotkey.bind(hyper, "Return", moveFocusedToNextScreen)
            hs.hotkey.bind(hyper, "0", rescueWindows)
            hs.hotkey.bind(hyper, "M", toggleInputMute)
            hs.hotkey.bind(hyper, "A", cycleOutputDevice)
            hs.hotkey.bind(hyper, "C", toggleMeetingMode)
            hs.hotkey.bind(hyper, "R", hs.reload)

            notify("Hammerspoon", "config loaded")
          '';

        "Library/Logs/hammerspoon/.keep".text = "";
      };

      shellAliases = {
        open-hammerspoon = "open -a Hammerspoon";
        reload-hammerspoon = "osascript -e 'tell application \"Hammerspoon\" to execute lua code \"hs.reload()\"'";
      };
    };

    launchd.agents.hammerspoon.config = {
      ProgramArguments = [
        "/usr/bin/open"
        "-g"
        "-a"
        "Hammerspoon"
      ];
      RunAtLoad = true;
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/hammerspoon/hammerspoon.err.log";
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/hammerspoon/hammerspoon.out.log";
    };
  };
}
