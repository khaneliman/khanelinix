_: _final: prev: {
  karabiner-elements = prev.karabiner-elements.overrideAttrs (_old: {
    # Keep the helper app bundles pristine so SMAppService can validate their
    # embedded plists and register them with Background Task Management.
    postPatch = "";
  });
}
