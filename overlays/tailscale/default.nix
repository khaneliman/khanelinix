_: _final: prev: {
  tailscale =
    let
      buildGoModule = prev.buildGoModule.override {
        go = prev.go.overrideAttrs {
          version = "1.25.1";
          src = prev.fetchurl {
            url = "https://go.dev/dl/go1.25.1.src.tar.gz";
            hash = "sha256-0BDBCc7pTYDv5oHqtGvepJGskGv0ZYPDLp8NuwvRpZQ=";
          };
        };
      };
    in
    (prev.tailscale.override { inherit buildGoModule; }).overrideAttrs {
      version = "1.88.1";
      src = prev.fetchFromGitHub {
        owner = "tailscale";
        repo = "tailscale";
        tag = "v1.88.1";
        hash = "sha256-hpj5yS02rQEGAu4VwHDTVx6SIOw7DQFv9SKkJtal6kk=";
      };
      vendorHash = "sha256-8aE6dWMkTLdWRD9WnLVSzpOQQh61voEnjZAJHtbGCSs=";
    };
}
