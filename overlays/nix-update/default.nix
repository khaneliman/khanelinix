_: _final: prev: {
  nix-update = prev.nix-update.overrideAttrs (_old: {
    src = prev.fetchFromGitHub {
      owner = "Mic92";
      repo = "nix-update";
      rev = "refs/pull/202/head";
      hash = "sha256-OSD8gERP4wCCw2Y3ycnIJo8J4vjM6G0pz/5mC/p+F5Q=";
    };
  });
}
