{
  config,
  khanelinix-lib,
  lib,
  options,
  inputs,
  ...
}:
let
  inherit (lib) types mkAliasDefinitions;
  inherit (khanelinix-lib) mkOpt;
in
{
  imports = lib.optional (
    inputs.home-manager ? nixosModules
  ) inputs.home-manager.nixosModules.home-manager;

  options.khanelinix.home = with types; {
    configFile =
      mkOpt attrs { }
        "A set of files to be managed by home-manager's <option>xdg.configFile</option>.";
    extraOptions = mkOpt attrs { } "Options to pass directly to home-manager.";
    file = mkOpt attrs { } "A set of files to be managed by home-manager's <option>home.file</option>.";
  };

  config = lib.optionalAttrs (inputs.home-manager ? nixosModules) {
    khanelinix.home.extraOptions = {
      home.file = mkAliasDefinitions options.khanelinix.home.file;
      home.stateVersion = config.system.stateVersion;
      xdg.configFile = mkAliasDefinitions options.khanelinix.home.configFile;
      xdg.enable = true;
    };

    home-manager = {
      # enables backing up existing files instead of erroring if conflicts exist
      backupFileExtension = "hm.old";

      useGlobalPkgs = true;
      useUserPackages = true;

      users.${config.khanelinix.user.name} = mkAliasDefinitions options.khanelinix.home.extraOptions;

      verbose = true;
    };
  };
}
