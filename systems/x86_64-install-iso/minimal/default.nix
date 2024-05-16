{ pkgs, lib, ... }:
let
  inherit (lib) mkForce;
  inherit (lib.internal) enabled;
in
{
  # `install-iso` adds wireless support that
  # is incompatible with networkmanager.
  networking.wireless.enable = mkForce false;

  environment.systemPackages = with pkgs; [
    git
    wget
    curl
    pciutils
    file
  ];

  khanelinix = {
    nix = enabled;

    programs = {
      terminal = {
        editors = {
          neovim = enabled;
          tmux = enabled;
        };
      };
    };

    services = {
      openssh = enabled;
    };

    security = {
      doas = enabled;
    };

    system = {
      boot = enabled;
      fonts = enabled;
      locale = enabled;
      time = enabled;
      xkb = enabled;
      networking = enabled;
    };
  };
}
