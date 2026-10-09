{ flake }:
let
  f = flake;
  home = {
    home = {
      username = "example";
      homeDirectory = "/home/example";
      stateVersion = "26.05";
    };
    khanelinix = {
      user = {
        enable = true;
        name = "example";
        fullName = "Example User";
        email = "user@example.invalid";
      };
      packageProfile = "core";
      suites.development = {
        enable = true;
        aiEnable = false;
      };
      services.sops.enable = true;
      programs.terminal.tools = {
        ssh.enable = true;
        git = {
          enable = true;
          signByDefault = false;
        };
      };
    };
  };
  mkHome =
    system: extraModules:
    let
      pkgs = import (if system == "aarch64-darwin" then f.inputs.nixpkgs-unstable else f.inputs.nixpkgs) (
        f.lib.system.common.mkNixpkgsConfig f // { inherit system; }
      );
    in
    f.inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        f.homeManagerModules.default
        home
      ]
      ++ extraModules;
    };
in
{
  nixos = f.inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      f.nixosModules.default
      {
        networking.hostName = "first-host";
        boot.loader.grub.enable = false;
        fileSystems."/" = {
          device = "none";
          fsType = "tmpfs";
        };
        system.stateVersion = "26.05";
        programs.zsh.enable = true;
        khanelinix.user.name = "example";
        khanelinix.programs.terminal.tools.ssh.enable = true;
        home-manager.users.example = home;
      }
    ];
  };
  darwin = f.inputs.nix-darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    modules = [
      f.darwinModules.default
      {
        networking.hostName = "first-host";
        system.stateVersion = 6;
        system.primaryUser = "example";
        khanelinix.user.name = "example";
        homebrew.enable = false;
        home-manager.users.example = home // {
          home = home.home // {
            homeDirectory = "/Users/example";
          };
        };
      }
    ];
  };
  home = mkHome "x86_64-linux" [ ];
  homeDarwin = mkHome "aarch64-darwin" [
    { home.homeDirectory = f.inputs.nixpkgs.lib.mkForce "/Users/example"; }
  ];
}
