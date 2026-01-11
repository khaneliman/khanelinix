{
  config,
  lib,
  pkgs,
  username ? null,

  ...
}:
let
  inherit (lib)
    types
    mkIf
    mkDefault
    mkMerge
    getExe
    getExe'
    ;
  inherit (lib.khanelinix) mkOpt enabled;

  cfg = config.khanelinix.user;

  home-directory =
    if cfg.name == null then
      null
    else if pkgs.stdenv.hostPlatform.isDarwin then
      "/Users/${cfg.name}"
    else
      "/home/${cfg.name}";

  getDir =
    dir: default:
    if config.xdg.userDirs.enable then
      lib.removePrefix "${config.home.homeDirectory}/" dir
    else
      default;
in
{
  options.khanelinix.user = {
    enable = mkOpt types.bool false "Whether to configure the user account.";
    email = mkOpt types.str "khaneliman12@gmail.com" "The email of the user.";
    fullName = mkOpt types.str "Austin Horstman" "The full name of the user.";
    home = mkOpt (types.nullOr types.str) home-directory "The user's home directory.";
    icon =
      mkOpt (types.nullOr types.package) pkgs.khanelinix.user-icon
        "The profile picture to use for the user.";
    name = mkOpt (types.nullOr types.str) username "The user account.";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = cfg.name != null;
          message = "khanelinix.user.name must be set";
        }
        {
          assertion = cfg.home != null;
          message = "khanelinix.user.home must be set";
        }
      ];

      home = {
        file = {
          "${getDir config.xdg.userDirs.desktop "Desktop"}/.keep".text = "";
          "${getDir config.xdg.userDirs.documents "Documents"}/.keep".text = "";
          "${getDir config.xdg.userDirs.download "Downloads"}/.keep".text = "";
          "${getDir config.xdg.userDirs.music "Music"}/.keep".text = "";
          "${getDir config.xdg.userDirs.pictures "Pictures"}/.keep".text = "";
          "${getDir config.xdg.userDirs.videos "Videos"}/.keep".text = "";
        }
        // lib.optionalAttrs (cfg.icon != null) {
          ".face".source = cfg.icon;
          ".face.icon".source = cfg.icon;
          "${getDir config.xdg.userDirs.pictures "Pictures"}/${
            cfg.icon.fileName or (baseNameOf cfg.icon)
          }".source =
            cfg.icon;
        };

        # Only set homeDirectory if cfg.home is not null
        homeDirectory = mkIf (cfg.home != null) (mkDefault cfg.home);

        shellAliases = {
          # nix specific aliases
          cleanup = "sudo nix-collect-garbage --delete-older-than 3d && nix-collect-garbage -d";
          bloat = "nix path-info -Sh /run/current-system";
          curgen = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
          gc-check = "nix-store --gc --print-roots | egrep -v \"^(/nix/var|/run/\w+-system|\{memory|/proc)\"";
          repair = "nix-store --verify --check-contents --repair";
          nixnuke = ''
            # Kill nix-daemon and nix processes first
            sudo pkill -9 -f "nix-(daemon|store|build)" || true

            # Find and kill all nixbld processes
            for pid in $(ps -axo pid,user | ${getExe pkgs.gnugrep} -E '[_]?nixbld[0-9]+' | ${getExe pkgs.gawk} '{print $1}'); do
              sudo kill -9 "$pid" 2>/dev/null || true
            done

            # Restart nix-daemon based on platform
            if [ "$(uname)" = "Darwin" ]; then
              sudo launchctl kickstart -k system/org.nixos.nix-daemon
            else
              sudo systemctl restart nix-daemon.service
            fi
          '';
          flake = "nix flake";
          nix = "nix -vL";
          gsed = "${getExe pkgs.gnused}";
          hmvar-reload = ''__HM_ZSH_SESS_VARS_SOURCED=0 source "/etc/profiles/per-user/${config.khanelinix.user.name}/etc/profile.d/hm-session-vars.sh"'';

          # File management
          rcp = "${getExe pkgs.rsync} -rahP --mkpath --modify-window=1"; # Rsync copy keeping all attributes,timestamps,permissions"
          rmv = "${getExe pkgs.rsync} -rahP --mkpath --modify-window=1 --remove-sent-files"; # Rsync move keeping all attributes,timestamps,permissions
          tarnow = "${getExe pkgs.gnutar} -acf ";
          untar = "${getExe pkgs.gnutar} -zxvf ";
          wget = "${getExe pkgs.wget} -c ";
          remove-empty = ''${getExe' pkgs.findutils "find"} . -type d -empty -delete'';
          print-empty = ''${getExe' pkgs.findutils "find"} . -type d -empty -print'';
          dfh = "${getExe' pkgs.coreutils "df"} -h";
          duh = "${getExe' pkgs.coreutils "du"} -h";
          usage = "${getExe' pkgs.coreutils "du"} -ah -d1 | sort -rn 2>/dev/null";

          # Navigation shortcuts
          home = "cd ~";
          ".." = "cd ..";
          "..." = "cd ../..";
          "...." = "cd ../../..";
          "....." = "cd ../../../..";
          "......" = "cd ../../../../..";

          # Colorize output
          dir = "${getExe' pkgs.coreutils "dir"} --color=auto";
          egrep = "${getExe' pkgs.gnugrep "egrep"} --color=auto";
          fgrep = "${getExe' pkgs.gnugrep "fgrep"} --color=auto";
          grep = "${getExe pkgs.gnugrep} --color=auto";
          vdir = "${getExe' pkgs.coreutils "vdir"} --color=auto";

          # Misc
          clear = "clear && ${getExe config.programs.fastfetch.package}";
          clr = "clear";
          pls = "sudo";
          psg = "${getExe pkgs.ps} aux | grep";
          myip = "${getExe pkgs.curl} ifconfig.me";

          # Cryptography
          genpass = "${getExe pkgs.openssl} rand - base64 20"; # Generate a random, 20-character password
          sha = "shasum -a 256"; # Test checksum
        };

        username = mkDefault cfg.name;
      };

      programs.home-manager = enabled;
    }
  ]);
}
