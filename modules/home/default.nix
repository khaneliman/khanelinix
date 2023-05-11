{ options
, config
, pkgs
, lib
, inputs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.home;
in
{
  imports = with inputs; [
    home-manager.nixosModules.home-manager
  ];

  options.khanelinix.home = with types; {
    file =
      mkOpt attrs { }
        "A set of files to be managed by home-manager's <option>home.file</option>.";
    configFile =
      mkOpt attrs { }
        "A set of files to be managed by home-manager's <option>xdg.configFile</option>.";
    extraOptions = mkOpt attrs { } "Options to pass directly to home-manager.";
  };

  config = {
    environment.systemPackages = with pkgs; [
      home-manager
    ];

    khanelinix.home.extraOptions = {
      home.stateVersion = config.system.stateVersion;
      home.file = mkAliasDefinitions options.khanelinix.home.file;
      xdg.enable = true;
      xdg.configFile = mkAliasDefinitions options.khanelinix.home.configFile;
    };

    home-manager = {
      useUserPackages = true;

      users.${config.khanelinix.user.name} =
        mkAliasDefinitions options.khanelinix.home.extraOptions;
    };
  };
}
