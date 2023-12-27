_: _final: prev: {
  # TODO: remove once fix makes it to nixos-unstable
  deno = prev.deno.overrideAttrs (old: {
    buildInputs = prev.lib.optionals prev.stdenv.isDarwin (
      [ prev.libiconv prev.darwin.libobjc ] ++
      (with prev.darwin.apple_sdk_11_0.frameworks; [
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
}
