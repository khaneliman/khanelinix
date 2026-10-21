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

  # aggregateModules now fails for external kernel modules that bypass
  # modules_install (https://github.com/NixOS/nixpkgs/issues/575192).
  # ryzen-smu: https://github.com/NixOS/nixpkgs/pull/576504
  {
    url = "https://github.com/NixOS/nixpkgs/pull/576504.patch";
    hash = "sha256-JbHEwKtBBNKtTh+ttpnNtZrZKgkH8frSgE0lST+X62c=";
  }
  # zenpower: https://github.com/NixOS/nixpkgs/pull/576565
  {
    url = "https://github.com/NixOS/nixpkgs/commit/976984ad4730028f3537dfaf04e632e410b77889.patch";
    hash = "sha256-WiyxJ06WPucsmSngIg4jbqnIIwxgf/ZIPI+ccr3bjPg=";
  }
  # ddcci-driver: https://github.com/NixOS/nixpkgs/pull/576387
  {
    url = "https://github.com/NixOS/nixpkgs/commit/51a5fe95b29edbe2548c43677f3f032b17c1a8d2.patch";
    hash = "sha256-bRO/lIuhlwxeT+BgLs+YNcezvJASEchoi6bPz4/+d90=";
  }
  # kvmfr: https://github.com/NixOS/nixpkgs/pull/576593
  {
    url = "https://github.com/NixOS/nixpkgs/commit/cbfbb11a35266900a803abe8009635bdc9173e9e.patch";
    hash = "sha256-zhjcuKbG+Sr/H7nvqC5H30ETiugR/TpmA/s3TzXsvU4=";
  }
]
