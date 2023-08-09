{ options
, config
, lib
, inputs
, ...
}:
with lib;
with lib.internal; {
  imports = with inputs; [
    home-manager.darwinModules.home-manager
  ];

  options.khanelinix.home = with types; {
    file =
      mkOpt attrs { }
        "A set of files to be managed by home-manager's <option>home.file</option>.";
    configFile =
      mkOpt attrs { }
        "A set of files to be managed by home-manager's <option>xdg.configFile</option>.";
    extraOptions = mkOpt attrs { } "Options to pass directly to home-manager.";
    homeConfig = mkOpt attrs { } "Final config for home-manager.";
  };

  config = {
    khanelinix.home.extraOptions = {
      home.file = mkAliasDefinitions options.khanelinix.home.file;
      xdg.enable = true;
      xdg.configFile = mkAliasDefinitions options.khanelinix.home.configFile;
    };

    snowfallorg.user.${config.khanelinix.user.name}.home.config = mkAliasDefinitions options.khanelinix.home.extraOptions;

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;

      # users.${config.khanelinix.user.name} = args:
      #   mkAliasDefinitions options.khanelinix.home.extraOptions;
    };
  };
}
