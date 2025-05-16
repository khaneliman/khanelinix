{
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.system.env = lib.mkOption {
    apply = lib.mapAttrs (
      _n: v: if lib.isList v then lib.concatMapStringsSep ":" toString v else (toString v)
    );
    default = { };
    description = "A set of environment variables to set.";
    type =
      with lib.types;
      attrsOf (oneOf [
        str
        path
        (listOf (either str path))
      ]);
  };

  config = {
    home = {
      extraOutputsToInstall = [
        "bin"
        "dev"
        "doc"
        "include"
        "info"
        "share"
      ];
    };
  };
}
