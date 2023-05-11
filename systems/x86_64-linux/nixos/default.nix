{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
with lib.internal; {
  imports = [./hardware.nix];

  programs.sway.extraSessionCommands = ''
    WLR_NO_HARDWARE_CURSORS=1
  '';

  khanelinix = {
    nix = enabled;

    archetypes = {
      vm = enabled;
    };

    apps = {
      _1password = enabled;
      firefox = enabled;
      vscode = enabled;
    };

    cli-apps = {
      neovim = enabled;
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
      http = enabled;
      misc = enabled;
      oh-my-posh = enabled;
    };

    hardware = {
      # audio = enabled;
      networking = enabled;
    };

    services = {
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
      shell = {
        zsh = enabled;
        bash = enabled;
        fish = enabled;
      };
    };
  };

  services.xserver.displayManager.defaultSession = "gnome";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}
