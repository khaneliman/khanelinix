_: [
  # https://github.com/nix-community/home-manager/pull/9711
  # Pinned to the PR head commit; the `pull/<n>.patch` URL changes content on
  # every push, invalidating the hash.
  {
    url = "https://github.com/khaneliman/home-manager/commit/157dd3fcb107ee9050046f5e3d58907e20dce5f7.patch";
    hash = "sha256-Z+cVE4DuwbBH+sm3Xb8R1K10p3gAtLSYXtOnpYxJl4A=";
  }
  # Accepted entries:
  #
  # {
  #   url = "https://github.com/nix-community/home-manager/pull/123.patch";
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
]
