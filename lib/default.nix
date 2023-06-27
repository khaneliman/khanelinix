{
}: rec {
  override-meta = meta: package:
    package.overrideAttrs (_: {
      inherit meta;
    });
}
