{
  inputs,
  lib,
  self,
  ...
}:
{
  imports = lib.optional (inputs.ez-configs ? flakeModule) inputs.ez-configs.flakeModule;

  ezConfigs = {
    root = ../.;

    earlyModuleArgs = {
      namespace = "khanelinix";
    };

    globalArgs = {
      inherit inputs self;
      namespace = "khanelinix";
      khanelinix-lib = self.lib.khanelinix;
      root = ../.;
    };

    darwin = {
      configurationsDirectory = ../configurations/darwin;
      modulesDirectory = ../modules/darwin;
    };

    home = {
      configurationsDirectory = ../configurations/home;
      modulesDirectory = ../modules/home;
    };

    nixos = {
      configurationsDirectory = ../configurations/nixos;
      modulesDirectory = ../modules/nixos;
    };
  };
}
