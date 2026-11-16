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

  # Triton 3.9 fails to compile aotriton 0.12b kernels, which breaks every
  # ROCm torch build; Hydra's rocmPackages.aotriton has failed since
  # 2026-11-13. Revert the Triton 3.9 and torch 2.15 bump until nixpkgs
  # ships an aotriton that builds with it, for example
  # https://github.com/NixOS/nixpkgs/pull/584256.
  {
    url = "https://github.com/NixOS/nixpkgs/pull/584207.diff";
    hash = "sha256-fVFIXB//YISr2m2Ydt3I5x8br80hMnk8z/88HS2jg5c=";
    revert = true;
  }
]
