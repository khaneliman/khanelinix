_: _final: prev: {
  # TODO: remove after upstream fix lands in a tagged sketchybar release.
  sketchybar = prev.sketchybar.overrideAttrs (old: {
    version = "2.23.0-unstable-2026-06-03";

    src = prev.fetchFromGitHub {
      owner = "FelixKratz";
      repo = "SketchyBar";
      rev = "e15627fd770a9c4e24b9e604343fe531572f261b";
      hash = "sha256-96VHhwqImB9iXK64O9SimCbCSbAJF7+lAOfwHk73Bo8=";
    };

    doInstallCheck = false;

    passthru = (old.passthru or { }) // {
      upstreamRev = "e15627fd770a9c4e24b9e604343fe531572f261b";
    };

    meta = old.meta // {
      changelog = "https://github.com/FelixKratz/SketchyBar/commits/e15627fd770a9c4e24b9e604343fe531572f261b";
    };
  });
}
