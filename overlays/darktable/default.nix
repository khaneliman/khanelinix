_: _final: prev: {
  darktable = prev.darktable.overrideAttrs (
    old:
    prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
      # The GUI binary sleeps indefinitely during the sandboxed version check.
      versionCheckProgram = "${placeholder "out"}/bin/darktable-cli";
      versionCheckKeepEnvironment = (old.versionCheckKeepEnvironment or "") + " HOME";
      preVersionCheck = (old.preVersionCheck or "") + ''
        export HOME="$TMPDIR/darktable-home"
        mkdir -p "$HOME"
      '';
    }
  );
}
