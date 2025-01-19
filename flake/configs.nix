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

    globalArgs = {
      inherit inputs self;
      khanelinix-lib = self.lib.khanelinix;
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
