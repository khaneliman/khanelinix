{ inputs, ... }:
{
  imports = [
    inputs.ez-configs.flakeModule
  ];

  ezConfigs = {
    root = ../.;

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
