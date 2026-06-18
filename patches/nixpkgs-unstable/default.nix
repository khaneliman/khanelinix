_: [
  # Accepted entries:
  #
  # {
  #   url = "https://github.com/NixOS/nixpkgs/pull/123.patch";
  #   hash = "sha256-...";
  #
  #   # Optional; defaults to "fetchpatch2".
  #   fetcher = "fetchpatch";
  #
  #   # Optional; extra attributes pass through to selected fetcher.
  #   stripLen = 1;
  # }
  #
  # ./local.patch
  #
  # <patch derivation>
  {
    url = "https://github.com/NixOS/nixpkgs/pull/529980.patch";
    hash = "sha256-Q29wyyEXtp7ysJ98yaOh3WNqX8I6XLUwwS52VJ1HLrc=";
  }
]
