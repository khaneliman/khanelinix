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

  # vmTools: fix `img` collision with pkgs.img that breaks runInLinuxVM
  # consumers (nix-rosetta-builder disk image). Remove once nixpkgs-unstable
  # advances past 68d32ed6cb (merged 2026-06-11).
  {
    url = "https://github.com/NixOS/nixpkgs/commit/68d32ed6cbd986a84582b88780168d22adebd6fc.patch";
    hash = "sha256-rWqOF2m+D5EgYkFSDcfm3aXHIIfOzL3lPS4wy0s9TFk=";
  }
]
