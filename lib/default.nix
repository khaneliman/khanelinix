{
  lib,
  self,
  root,
  ...
}:
lib.makeExtensible (
  self':
  let
    call = lib.callPackageWith {
      inherit call self' lib;
    };
  in
  {
    audio = call ./audio/default.nix { };
    base64 = call ./base64/default.nix { };
    deploy = call ./deploy/default.nix {
      inherit (self) inputs;
    };
    file = call ./file/default.nix { inherit lib root; };
    module = call ./module/default.nix { };
    packages = call ./packages/default.nix { };
    network = call ./network/default.nix {
      inherit (self) inputs;
    };
    theme = call ./theme/default.nix { };

    inherit (self'.module)
      mkOpt
      mkOpt'
      mkBoolOpt
      mkBoolOpt'
      enabled
      disabled
      capitalize
      boolToNum
      default-attrs
      force-attrs
      nested-default-attrs
      nested-force-attrs
      ;

    inherit (self'.file)
      getDefaultNixFiles
      getDefaultNixFilesRecursive
      getFile
      getFilesList
      ;
  }
)
