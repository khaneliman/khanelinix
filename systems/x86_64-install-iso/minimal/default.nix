{ pkgs
, lib
, ...
}:
with lib;
with lib.internal; {
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

    cli-apps = {
      neovim = enabled;
      tmux = enabled;
    };

    tools = {
      git = enabled;
      node = enabled;
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
