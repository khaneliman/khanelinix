_: _final: prev: {
  bicep = prev.bicep.overrideAttrs (_oldAttrs: {
    meta.broken = false;
  });
}
