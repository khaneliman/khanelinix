# patchelf 0.19.2 corrupts or aborts on some prebuilt binaries
# (https://github.com/NixOS/patchelf/issues/674). Pin the affected consumers to
# 0.15.2, as nixpkgs does for CUDA, until nixpkgs ships
# https://github.com/NixOS/patchelf/pull/672.
_: final: prev:
let
  # Only these packages pull NuGet packages with native tools (Grpc.Tools) that
  # patchelf aborts on. Swapping patchNupkgs for the whole scope would rebuild
  # the NuGet dependencies of every .NET package.
  dotnetCorePackages = prev.dotnetCorePackages.overrideScope (
    _: dotnetPrev: {
      patchNupkgs = dotnetPrev.patchNupkgs.override { patchelf = final.patchelf_0_15; };
    }
  );
in
{
  patchelf_0_15 = prev.patchelf.overrideAttrs (
    finalAttrs: _: {
      version = "0.15.2";
      src = prev.fetchurl {
        url = "https://github.com/NixOS/patchelf/releases/download/${finalAttrs.version}/patchelf-${finalAttrs.version}.tar.bz2";
        hash = "sha256-F3RfVkFZyOIo/EEtplogSLhGxLa0Igt3y/IkFuAvLXw=";
      };
    }
  );

  azure-functions-core-tools = prev.azure-functions-core-tools.override {
    inherit (dotnetCorePackages) buildDotnetModule;
  };

  bicep = prev.bicep.override { inherit (dotnetCorePackages) buildDotnetModule; };
}
