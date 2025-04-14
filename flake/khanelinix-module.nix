{
  lib,
  namespace,
  khanelinix-lib,
  ...
}:
{
  _module.args = {
    lib = lib.extend (
      _final: _prev: {
        ${namespace} = khanelinix-lib;
      }
    );
  };
}
