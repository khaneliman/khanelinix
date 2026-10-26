{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkOption types;
in
{
  options.khanelinix.system.tcc.stableBinaries = mkOption {
    type = types.attrsOf (
      types.submodule (
        { name, ... }:
        {
          options = {
            source = mkOption {
              type = types.str;
              description = "Executable to install at the stable path.";
            };

            path = mkOption {
              type = types.str;
              readOnly = true;
              default = "${config.home.homeDirectory}/.local/bin/${name}-stable";
              description = "Stable path that launchd runs and TCC records.";
            };
          };
        }
      )
    );
    default = { };
    description = ''
      Executables that need a TCC grant, keyed by name. nix-darwin activation
      installs each one at a fixed path, because TCC records the client path
      and Nix store paths change on every rebuild.
    '';
  };
}
