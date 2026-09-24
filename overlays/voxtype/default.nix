_: final: prev: {
  voxtype-onnx = prev.voxtype-onnx.overrideAttrs (
    finalAttrs: old:
    let
      # Nemotron cache-aware streaming (peteonrails/voxtype#699).
      nemotronPatches = [
        (final.fetchpatch2 {
          name = "voxtype-nemotron-streaming.patch";
          url = "https://github.com/peteonrails/voxtype/commit/5522f32768bd90c0ebcdbb3111c9a0d72070fb6e.patch";
          hash = "sha256-vrMN2cTIh8G/41y/K8pjZlwFbrkM3vs7+nBDb2ux8tY=";
        })
        (final.fetchpatch2 {
          name = "voxtype-nemotron-integration.patch";
          url = "https://github.com/peteonrails/voxtype/commit/2e1aa958c1cedc35f8139b14799f620a61b03757.patch";
          hash = "sha256-rtMhG0PZNTyZZclWWY9HXocfTBRDqM0cJbYLA3lB8N0=";
        })
      ];
    in
    {
      version = "1.1.0";

      src = final.fetchFromGitHub {
        owner = "peteonrails";
        repo = "voxtype";
        tag = "v${finalAttrs.version}";
        hash = "sha256-zw7Up84IdNv6p8Ae7VnBDuCC/smYHCpMB7C2aN1ZXyc=";
      };

      patches =
        (old.patches or [ ])
        ++ nemotronPatches
        ++ [
          ./streaming-session-hooks.patch
          # Type the tail the backend drains after stop, within one second.
          ./streaming-finish.patch
          # Apply [text] replacements to streamed partials, holding back only
          # words that could still start a replacement.
          ./streaming-replacements.patch
          # `voxtype learn` (peteonrails/voxtype#668), minus its authors line.
          (final.fetchpatch2 {
            name = "voxtype-learn.patch";
            url = "https://github.com/peteonrails/voxtype/commit/9dc192fa2b458a857cfc9e800e5e2653a3f2ff40.patch";
            excludes = [ "Cargo.toml" ];
            hash = "sha256-6yVsCzxh8bNPoZKhor5M+ZHbfj3OSPNpunjaYxFTNx8=";
          })
          # Learn into a writable state file the daemon rereads per session,
          # since the generated config.toml is read-only.
          ./learned-replacements.patch
        ];

      # fetchCargoVendor recurses forever into an ancestor symlink inside the
      # openvino-rs Git checkout; importCargoLock tolerates it. The lockfile is
      # the patched tree's Cargo.lock.
      cargoDeps = final.rustPlatform.importCargoLock {
        lockFile = ./Cargo.lock;
        outputHashes = final.lib.genAttrs [
          "openvino-finder-0.11.0"
          "openvino-genai-0.11.0"
          "openvino-genai-sys-0.11.0"
          "openvino-sys-0.11.0"
        ] (_: "sha256-nQWeHNdLlRk+owh3B6VpArAG2dr66HeBI2RHfDhyvvU=");
      };
    }
  );
}
