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
      runCmd = if isCommand then dirPath else "cd ${dirPath}";
      description =
        if isCommand then
          desc
        else if desc != null then
          "Go to the ${desc} directory"
        else
          "Go to the ${dirPath} directory";
    in
    {
      on = [
        "g"
        key
      ];
      run = runCmd;
      desc = description;
    };

  getDir =
    dir: default: if config.xdg.userDirs.enable then dir else "${config.home.homeDirectory}/${default}";

  commonLocations = [
    {
      key = "/";
      dirPath = "/";
    }
    {
      key = "<Space>";
      dirPath = "cd --interactive";
      isCommand = true;
      desc = "Go to a directory interactively";
    }
    {
      key = "c";
      dirPath = config.xdg.configHome;
      desc = "~/.config";
    }
    {
      key = "d";
      dirPath = getDir config.xdg.userDirs.documents "Documents";
      desc = "~/Documents";
    }
    {
      key = "D";
      dirPath = getDir config.xdg.userDirs.download "Downloads";
      desc = "~/Downloads";
    }
    {
      key = "e";
      dirPath = "/etc";
    }
    {
      key = "g";
      dirPath = "${getDir config.xdg.userDirs.documents (lib.optionalString pkgs.stdenv.hostPlatform.isLinux "Documents")}/github";
      desc = "~/Documents/github";
    }
    {
      key = "G";
      dirPath = "${getDir config.xdg.userDirs.documents (lib.optionalString pkgs.stdenv.hostPlatform.isLinux "Documents")}/gitlab";
      desc = "~/Documents/gitlab";
    }
    {
      key = "h";
      dirPath = config.home.homeDirectory;
      desc = "~";
    }
    {
      key = "k";
      dirPath = getDir config.xdg.userDirs.desktop "Desktop";
      desc = "~/Desktop";
    }
    {
      key = "l";
      dirPath = "${config.home.homeDirectory}/.local/";
      desc = "~/.local";
    }
    {
      key = "p";
      dirPath = getDir config.xdg.userDirs.pictures "Pictures";
      desc = "~/Pictures";
    }
    {
      key = "r";
      dirPath = /* Bash */ ''shell -- ya emit cd "$(git rev-parse --show-toplevel)"'';
      isCommand = true;
      desc = "Go to the root of git directory";
    }
    {
      key = "t";
      dirPath = "/tmp";
    }
    {
      key = "u";
      dirPath = "/usr";
    }
    {
      key = "V";
      dirPath = getDir config.xdg.userDirs.videos "Videos";
      desc = "~/Videos";
    }
    {
      key = "w";
      dirPath = "${config.xdg.dataHome}/wallpapers";
      desc = "~/.local/share/wallpapers";
    }
  ];

  linuxLocations = [
    {
      key = "H";
      dirPath = "/nix/var/nix/profiles/per-user/${config.khanelinix.user.name}/home-manager";
      desc = "/nix/var/.../home-manager";
    }
    {
      key = "i";
      dirPath = "/run/media/${config.khanelinix.user.name}";
      desc = "/run/media/${config.khanelinix.user.name}";
    }
    {
      key = "m";
      dirPath = "/media";
    }
    {
      key = "M";
      dirPath = "/mnt";
    }
    {
      key = "n";
      dirPath = "/run/current-system";
    }
    {
      key = "o";
      dirPath = "/opt";
    }
    {
      key = "R";
      dirPath = "/run";
    }
    {
      key = "s";
      dirPath = "/srv";
    }
    {
      key = "v";
      dirPath = "/var";
    }
  ];

  darwinLocations = [
    {
      key = "a";
      dirPath = "${config.home.homeDirectory}/Applications";
      desc = "~/Applications";
    }
    {
      key = "A";
      dirPath = "/Applications";
    }
    {
      key = "b";
      dirPath = "${config.home.homeDirectory}/.Trash";
      desc = "~/.Trash";
    }
    {
      key = "C";
      dirPath = "${config.home.homeDirectory}/Library/Mobile Documents/com~apple~CloudDocs";
      desc = "~/Library/.../CloudDocs";
    }
    {
      key = "H";
      dirPath = "${config.xdg.stateHome}/home-manager/gcroots";
      desc = "~/.local/state/home-manager/gcroots";
    }
    {
      key = "L";
      dirPath = "${config.home.homeDirectory}/Library";
      desc = "~/Library";
    }
    {
      key = "n";
      dirPath = "/run/current-system";
    }
    {
      key = "P";
      dirPath = "${config.home.homeDirectory}/Library/CloudStorage/ProtonDrive-${config.khanelinix.user.email}";
      desc = "~/Library/.../ProtonDrive";
    }
    {
      key = "v";
      dirPath = "/var";
    }
  ];

  # Available keys:
  # B, f, F, j, J, q, Q, x, X, y, Y, z, Z, K, N, O, S, U, W, I
  # Used keys:
  # /, <Space>, h, c, t, d, D, e, g, G, k, l, p, r, u, V, w, i, M, m, n, o, R, s, v, H, A, a, C, L, P, b
  gotoLocations =
    commonLocations
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux linuxLocations
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin darwinLocations;
in
{
  prepend_keymap = map mkGotoKeymap (builtins.sort (a: b: a.key < b.key) gotoLocations);
}
