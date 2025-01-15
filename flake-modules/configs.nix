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

    nixos = {
      configurationsDirectory = ../configurations/nixos;
      modulesDirectory = ../modules/nixos;
    };
  };
}
