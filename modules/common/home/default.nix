{
  config,
  lib,
  options,
  pkgs,

  ...
}:
let
  inherit (lib.khanelinix) mkOpt;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
in
{
  options.khanelinix.home = {
    file =
      mkOpt lib.types.attrs { }
        "A set of files to be managed by home-manager's <option>home.file</option>.";
    configFile =
      mkOpt lib.types.attrs { }
        "A set of files to be managed by home-manager's <option>xdg.configFile</option>.";
    extraOptions = mkOpt lib.types.attrs { } "Options to pass directly to home-manager.";
  };

  config = {
    # extraOptions uses types.attrs, so separate home or xdg definitions merge shallowly.
    khanelinix.home.extraOptions = {
      home = {
        file = lib.mkAliasDefinitions options.khanelinix.home.file;
      }
      // lib.optionalAttrs isLinux { stateVersion = lib.mkOptionDefault config.system.stateVersion; };
      xdg.configFile = lib.mkAliasDefinitions options.khanelinix.home.configFile;
      xdg.enable = if isLinux then lib.mkDefault true else true;
    };

    home-manager.users = lib.mkIf (config.khanelinix.user.name != null) {
      ${config.khanelinix.user.name} = lib.mkAliasDefinitions options.khanelinix.home.extraOptions;
    };

    home-manager = {
      # enables backing up existing files instead of erroring if conflicts exist
      backupFileExtension = "hm.old";

      useUserPackages = true;
      useGlobalPkgs = true;

      verbose = true;
    };
  };
}
