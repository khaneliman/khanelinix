{ modulesPath, inputs, ... }:
{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    inputs.nixos-wsl.nixosModules.wsl
  ];

  wsl = {
    enable = true;
    defaultUser = "nixos";
    startMenuLaunchers = true;

    wslConf = {
      automount = {
        root = "/mnt";
      };
    };

    # Enable native Docker support
    # docker-native.enable = true;

    # Enable integration with Docker Desktop (needs to be installed)
    # docker-desktop.enable = true;
  };
}
