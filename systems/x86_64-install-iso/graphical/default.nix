{ pkgs
, lib
, ...
}:
let
  inherit (lib) mkForce;
  inherit (lib.internal) enabled;
in
{
  # `install-iso` adds wireless support that
  # is incompatible with networkmanager.
  networking.wireless.enable = mkForce false;

  environment.systemPackages = with pkgs; [
    wget
    curl
    pciutils
    file
  ];

  khanelinix = {
    nix = enabled;

    apps = {
      _1password = enabled;
      firefox = enabled;
      gparted = enabled;
    };

    cli-apps = {
      astronvim = enabled;
      tmux = enabled;
    };

    desktop = {
      gnome = {
        enable = true;
      };

      addons = {
        # I like to have a convenient place to share wallpapers from
        # even if they're not currently being used.
        wallpapers = enabled;
      };
    };

    tools = {
      k8s = enabled;
      git = enabled;
      node = enabled;
    };

    hardware = {
      audio = enabled;
    };

    services = {
      openssh = enabled;
      printing = enabled;
    };

    security = {
      doas = enabled;
      keyring = enabled;
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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}
