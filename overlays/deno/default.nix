_: (_self: super: {
  # TODO: remove once fix makes it to nixos-unstable
  deno = super.deno.overrideAttrs (old: {
    buildInputs = super.lib.optionals super.stdenv.isDarwin (
      [ super.libiconv super.darwin.libobjc ] ++
      (with super.darwin.apple_sdk_11_0.frameworks; [
        Security
        CoreServices
        Metal
        MetalPerformanceShaders
        Foundation
        QuartzCore
      ])
    );

    postPatch = ''
      # upstream uses lld on aarch64-darwin for faster builds
      # within nix lld looks for CoreFoundation rather than CoreFoundation.tbd and fails
      substituteInPlace .cargo/config.toml --replace "-fuse-ld=lld " ""
    '';
  });
})
