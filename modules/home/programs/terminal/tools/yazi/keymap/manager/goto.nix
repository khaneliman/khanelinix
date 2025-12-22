{
  config,
  lib,

  pkgs,
  ...
}:
let
  mkGotoKeymap =
    {
      key,
      path,
      desc ? null,
      isCommand ? false,
    }:
    let
      defaultDesc =
        if isCommand then
          null # Commands must provide their own descriptions
        else
          "Go to the ${path} directory";

      description = if desc != null then desc else defaultDesc;

      runCmd = if isCommand then path else "cd ${path}";
    in
    {
      on = [
        "g"
        key
      ];
      run = runCmd;
      desc = description;
    };

  # Define all goto locations with minimal required information
  gotoLocations = [
    {
      key = "/";
      path = "/";
    }
    {
      key = "h";
      path = "~";
      desc = "Go to the home directory";
    }
    {
      key = "c";
      path = "~/.config";
    }
    {
      key = "t";
      path = "/tmp";
    }
    {
      key = "<Space>";
      path = "cd --interactive";
      isCommand = true;
      desc = "Go to a directory interactively";
    }
    {
      key = "D";
      path = "~/Downloads";
    }
    {
      key = "G";
      path = "~/${lib.optionalString pkgs.stdenv.hostPlatform.isLinux "Documents/"}gitlab";
    }
    {
      key = "M";
      path = "/mnt";
    }
    {
      key = "d";
      path = "~/Documents";
    }
    {
      key = "e";
      path = "/etc";
    }
    {
      key = "g";
      path = "~/${lib.optionalString pkgs.stdenv.hostPlatform.isLinux "Documents/"}github";
    }
    {
      key = "i";
      path = "/run/media/${config.khanelinix.user.name}";
      desc = "Go to the media directory";
    }
    {
      key = "l";
      path = "~/.local/";
    }
    {
      key = "m";
      path = "/media";
    }
    {
      key = "o";
      path = "/opt";
    }
    {
      key = "p";
      path = "~/Pictures";
    }
    {
      key = "R";
      path = "/run";
    }
    {
      key = "r";
      path = ''shell -- ya emit cd "$(git rev-parse --show-toplevel)"'';
      isCommand = true;
      desc = "Go to the root of git directory";
    }
    {
      key = "s";
      path = "/srv";
    }
    {
      key = "u";
      path = "/usr";
    }
    {
      key = "v";
      path = "/var";
    }
    {
      key = "w";
      path = "~/.local/share/wallpapers";
    }
    {
      key = "n";
      path = "/run/current-system";
      desc = "Go to the current NixOS system profile";
    }
    {
      key = "H";
      path =
        if pkgs.stdenv.hostPlatform.isLinux then
          "/nix/var/nix/profiles/per-user/${config.khanelinix.user.name}/home-manager"
        else
          "~/.local/state/home-manager/gcroots";
      desc = "Go to the home-manager profile";
    }
  ];
in
{
  prepend_keymap = map mkGotoKeymap gotoLocations;
}
