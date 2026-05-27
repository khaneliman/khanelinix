/**
  This file is used by nixd's expressions to find the current flake.

  Ported from khanelivim (modules/nixvim/lsp/_nixd-expr.nix), originally
  yoinked from MattSturgeon/nix-config commit
  b8aa42d6c01465949ef5cd9d4dc086d4eaa36793.

  The `local` attr is the flake the current working directory falls within.
  Found by searching upwards from the current directory, looking for a path
  that contains a `flake.nix` file.
  `local` will be `null` if no local flake is found (including pure-eval, where
  `builtins.getEnv "PWD"` returns "" and the upward walk short-circuits).

  The `global` attr is the flake evaluated by the `self` argument. This should
  usually be this flake's in-store path.

  ## Usage

  ```nix
  with import ./nixd-expr.nix { self = "<flake>"; }; «expr»
  ```
*/
{
  self,
  system ? builtins.currentSystem,
}:
let

  # Reimplementation of `lib.lists.dropEnd 1` using builtins
  dropLast =
    list:
    let
      len = builtins.length list;
      dropped = builtins.genList (builtins.elemAt list) (len - 1);
    in
    if list == [ ] || len == 1 then [ ] else dropped;

  # Walk up the directory path, looking for a flake.nix file
  # Called with an absolute filepath
  findFlake =
    dir:
    let
      isPart = part: builtins.isString part && part != "" && part != ".";
      parts = builtins.filter isPart (builtins.split "/+" dir);
    in
    findFlake' parts;

  # Underlying impl of findFlake
  # Called with a list path instead of a string path
  findFlake' =
    parts:
    let
      dir = "/" + builtins.concatStringsSep "/" parts;
      files = builtins.readDir dir;
      isFlake = files."flake.nix" or null == "regular";
      parent = dropLast parts;
    in
    if parts == [ ] then
      null
    else if isFlake then
      dir
    else
      findFlake' parent;

  # Path to the local flake, or null
  flakePath = findFlake (builtins.getEnv "PWD");
in
{
  inherit system self;
  path = flakePath;

  local = if flakePath == null then null else builtins.getFlake flakePath;
  global = builtins.getFlake self;
}
