_: _final: prev:
{
  blender = prev.blender.overrideAttrs (old: {
    patches = old.patches ++ [
      (prev.fetchpatch {
        url = "https://projects.blender.org/blender/blender/commit/cf4365e555a759d5b3225bce77858374cb07faad.diff";
        hash = "sha256-Nypd04yFSHYa7RBa8kNmoApqJrU4qpaOle3tkj44d4g=";
      })
    ];
  });
}
