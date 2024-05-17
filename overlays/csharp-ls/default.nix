_: _final: prev: {
  csharp-ls = prev.csharp-ls.overrideAttrs (_oldAttrs: {
    # NOTE: csharp-ls requires a very new dotnet 8 sdk. This causes issues with workspace dotnet
    # collisions because dotnet commands will run off the newest SDK breaking working with lower
    # version projects.
    useDotnetFromEnv = false;
  });
}
