{ lib, ... }:
let
  inherit (lib) mkForce;
  inherit (lib.internal) enabled disabled;
in
{
  imports = [ ./hardware.nix ];

  khanelinix = {
    nix = enabled;

    archetypes = {
      wsl = enabled;
    };

    apps = {
      yubikey = enabled;
    };

    cli-apps = {
      yubikey = enabled;
    };

    security = {
      gpg = mkForce disabled;
    };

    suites = {
      business = enabled;
      common = enabled;
      development = enabled;
    };

    user = {
      name = "nixos";
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
