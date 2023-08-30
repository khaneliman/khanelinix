{ modulesPath
, inputs
, ...
}:
let
  inherit (inputs) nixos-hardware;
in
{
  imports = with nixos-hardware.nixosModules; [
    "${modulesPath}/profiles/minimal.nix"
    inputs.nixos-wsl.nixosModules.wsl
    common-pc
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
