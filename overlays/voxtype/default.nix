_: _final: prev: {
  voxtype-onnx = prev.voxtype-onnx.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./streaming-session-hooks.patch ];
  });
}
