_: final: prev: {
  bicep = prev.bicep.overrideAttrs (
    old:
    final.lib.optionalAttrs final.stdenv.buildPlatform.isDarwin {
      # Grpc.Tools bundles x86_64-only macOS binaries; use native build tools.
      env = (old.env or { }) // {
        PROTOBUF_PROTOC = final.lib.getExe final.buildPackages.protobuf;
        GRPC_PROTOC_PLUGIN = final.lib.getExe' final.buildPackages.grpc "grpc_csharp_plugin";
      };
    }
  );
}
