_: _final: prev: {
  aerospace = prev.aerospace.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      app_plist="$out/Applications/AeroSpace.app/Contents/Info.plist"
      if [ -f "$app_plist" ]; then
        /usr/libexec/PlistBuddy -c "Set :NSMicrophoneUsageDescription AeroSpace hotkeys can trigger voice dictation and need microphone access." "$app_plist" \
          || /usr/libexec/PlistBuddy -c "Add :NSMicrophoneUsageDescription string AeroSpace hotkeys can trigger voice dictation and need microphone access." "$app_plist"
      fi
    '';
  });
}
