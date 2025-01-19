{
  config,
  khanelinix-lib,
  lib,
  options,
  inputs,
  ...
}:
let
  inherit (khanelinix-lib) mkOpt;
in
{
  imports = lib.optional (
    inputs.home-manager ? darwinModules
  ) inputs.home-manager.darwinModules.home-manager;

  options.khanelinix.home = with lib.types; {
    file = mkOpt attrs { } "A set of files to be managed by home-manager's <option>home.file</option>.";
    configFile =
      mkOpt attrs { }
        "A set of files to be managed by home-manager's <option>xdg.configFile</option>.";
    extraOptions = mkOpt attrs { } "Options to pass directly to home-manager.";
    homeConfig = mkOpt attrs { } "Final config for home-manager.";
  };

  config = lib.optionalAttrs (inputs.home-manager ? darwinModules) {
    khanelinix.home.extraOptions = {
      home = {
        file = lib.mkAliasDefinitions options.khanelinix.home.file;
        # TODO: better default
        stateVersion = lib.mkDefault "24.11";
      };
      xdg = {
        enable = true;
        configFile = lib.mkAliasDefinitions options.khanelinix.home.configFile;
      };
    };

    home-manager = {
      # enables backing up existing files instead of erroring if conflicts exist
      backupFileExtension = "hm.old";

      useUserPackages = true;
      useGlobalPkgs = true;

      users.${config.khanelinix.user.name} = lib.mkAliasDefinitions options.khanelinix.home.extraOptions;

      verbose = true;
    };
  };
}
