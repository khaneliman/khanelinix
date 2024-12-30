_: _final: prev: {
  ardour = prev.ardour.override {
    librdf_raptor = prev.librdf_raptor2;
  };
}
