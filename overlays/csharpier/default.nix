_: _final: prev: {
  csharpier = prev.csharpier.overrideAttrs (oldAttrs: {
    postFixup =
      (oldAttrs.postFixup or "")
      + ''
        # Create symlink from dotnet-csharpier to csharpier
        ln -s $out/bin/dotnet-csharpier $out/bin/csharpier
      '';
  });
}
