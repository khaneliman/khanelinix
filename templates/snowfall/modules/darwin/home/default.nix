{
  config,
  lib,
  options,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkOpt;
in
{
  options.${namespace}.home = {
    file =
      mkOpt lib.types.attrs { }
        "A set of files to be managed by home-manager's <option>home.file</option>.";
    configFile =
      mkOpt lib.types.attrs { }
        "A set of files to be managed by home-manager's <option>xdg.configFile</option>.";
    extraOptions = mkOpt lib.types.attrs { } "Options to pass directly to home-manager.";
    homeConfig = mkOpt lib.types.attrs { } "Final config for home-manager.";
  };

  config = {
    ${namespace}.home.extraOptions = {
      home.file = lib.mkAliasDefinitions options.${namespace}.home.file;
      xdg.enable = true;
      xdg.configFile = lib.mkAliasDefinitions options.${namespace}.home.configFile;
    };

    snowfallorg.users.${config.${namespace}.user.name}.home.config =
      lib.mkAliasDefinitions
        options.${namespace}.home.extraOptions;

    home-manager = {
      # enables backing up existing files instead of erroring if conflicts exist
      backupFileExtension = "hm.old";

      useUserPackages = true;
      useGlobalPkgs = true;

      verbose = true;
    };
  };
}
