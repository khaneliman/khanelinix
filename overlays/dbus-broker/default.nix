_: _final: prev: {
  dbus-broker = prev.dbus-broker.overrideAttrs (old: {
    patches =
      (old.patches or [ ])
      ++ prev.lib.optionals prev.stdenv.hostPlatform.isLinux [
        (prev.fetchpatch2 {
          name = "dbus-broker-logging.patch";
          url = "https://github.com/user-attachments/files/28911250/dbus-broker-logging.patch";
          hash = "sha256-FqbhRjLHsqHjkB0p9fCLKgyWTB+VxvInXSy/29s25Lk=";
        })
      ];
  });
}
