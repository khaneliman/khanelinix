_: _final: prev: {
  sesh = prev.buildGoModule (finalAttrs: {
    pname = "sesh";
    version = "2.24.2";

    nativeBuildInputs = [
      prev.go-mockery
      prev.writableTmpDirAsHomeHook
    ];

    src = prev.fetchFromGitHub {
      owner = "joshmedeski";
      repo = "sesh";
      rev = "v${finalAttrs.version}";
      hash = "sha256-iisAIn4km/uFw2DohA2mjoYmKgDQ3lYUH284Le3xQD0=";
    };

    # Prevent vendor hash calculation from running the generated mocks first.
    overrideModAttrs = _: {
      preBuild = "";
    };

    preBuild = ''
      mockery
    '';

    vendorHash = "sha256-WHMQ7O5EZ43biR7HxjO9gUq8skFPCZVOx47NIPp5iSE=";

    ldflags = [
      "-s"
      "-w"
      "-X main.version=${finalAttrs.version}"
    ];

    nativeInstallCheckInputs = [ prev.versionCheckHook ];
    versionCheckKeepEnvironment = [ "HOME" ];
    doInstallCheck = true;

    meta = prev.sesh.meta // {
      changelog = "https://github.com/joshmedeski/sesh/releases/tag/${finalAttrs.src.rev}";
    };
  });
}
