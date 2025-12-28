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
      dirPath,
      desc ? null,
      isCommand ? false,
    }:
    let
      defaultDesc =
        if isCommand then
          null # Commands must provide their own descriptions
        else
          "Go to the ${dirPath} directory";

      description = if desc != null then desc else defaultDesc;

      runCmd = if isCommand then dirPath else "cd ${dirPath}";
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
      dirPath = "/";
    }
    {
      key = "h";
      dirPath = "~";
      desc = "Go to the home directory";
    }
    {
      key = "c";
      dirPath = "~/.config";
    }
    {
      key = "t";
      dirPath = "/tmp";
    }
    {
      key = "<Space>";
      dirPath = "cd --interactive";
      isCommand = true;
      desc = "Go to a directory interactively";
    }
    {
      key = "D";
      dirPath = "~/Downloads";
    }
    {
      key = "G";
      dirPath = "~/${lib.optionalString pkgs.stdenv.hostPlatform.isLinux "Documents/"}gitlab";
    }
    {
      key = "M";
      dirPath = "/mnt";
    }
    {
      key = "d";
      dirPath = "~/Documents";
    }
    {
      key = "e";
      dirPath = "/etc";
    }
    {
      key = "g";
      dirPath = "~/${lib.optionalString pkgs.stdenv.hostPlatform.isLinux "Documents/"}github";
    }
    {
      key = "i";
      dirPath = "/run/media/${config.khanelinix.user.name}";
      desc = "Go to the media directory";
    }
    {
      key = "l";
      dirPath = "~/.local/";
    }
    {
      key = "m";
      dirPath = "/media";
    }
    {
      key = "o";
      dirPath = "/opt";
    }
    {
      key = "p";
      dirPath = "~/Pictures";
    }
    {
      key = "R";
      dirPath = "/run";
    }
    {
      key = "r";
      dirPath = /* Bash */ ''shell -- ya emit cd "$(git rev-parse --show-toplevel)"'';
      isCommand = true;
      desc = "Go to the root of git directory";
    }
    {
      key = "s";
      dirPath = "/srv";
    }
    {
      key = "u";
      dirPath = "/usr";
    }
    {
      key = "v";
      dirPath = "/var";
    }
    {
      key = "w";
      dirPath = "~/.local/share/wallpapers";
    }
    {
      key = "n";
      dirPath = "/run/current-system";
      desc = "Go to the current NixOS system profile";
    }
    {
      key = "H";
      dirPath =
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
