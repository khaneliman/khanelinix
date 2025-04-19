_: _final: prev: {
  firefox-devedition-unwrapped = prev.firefox-devedition-unwrapped.override {
    apple-sdk_14 = prev.apple-sdk_15;
  };
}
