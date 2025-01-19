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
    inputs.home-manager ? nixosModules
  ) inputs.home-manager.nixosModules.home-manager;

  options.khanelinix.home = with lib.types; {
    file = mkOpt attrs { } "A set of files to be managed by home-manager's <option>home.file</option>.";
    configFile =
      mkOpt attrs { }
        "A set of files to be managed by home-manager's <option>xdg.configFile</option>.";
    extraOptions = mkOpt attrs { } "Options to pass directly to home-manager.";
    homeConfig = mkOpt attrs { } "Final config for home-manager.";
  };

  config = lib.optionalAttrs (inputs.home-manager ? nixosModules) {
    khanelinix.home.extraOptions = {
      home.file = lib.mkAliasDefinitions options.khanelinix.home.file;
      xdg.enable = true;
      xdg.configFile = lib.mkAliasDefinitions options.khanelinix.home.configFile;
    };

    snowfallorg.users.${config.khanelinix.user.name}.home.config =
      lib.mkAliasDefinitions options.khanelinix.home.extraOptions;

    home-manager = {
      # enables backing up existing files instead of erroring if conflicts exist
      backupFileExtension = "hm.old";

      useUserPackages = true;
      useGlobalPkgs = true;

      verbose = true;
    };
  };
}
