{ lib
, config
, pkgs
, ...
}:
let
  inherit (lib) types mkIf mkDefault mkMerge getExe;
  inherit (lib.internal) mkOpt;

  cfg = config.khanelinix.user;
  is-darwin = pkgs.stdenv.isDarwin;

  home-directory =
    if cfg.name == null
    then null
    else if is-darwin
    then "/Users/${cfg.name}"
    else "/home/${cfg.name}";
in
{
  options.khanelinix.user = {
    enable = mkOpt types.bool false "Whether to configure the user account.";
    name = mkOpt (types.nullOr types.str) config.snowfallorg.user.name "The user account.";

    fullName = mkOpt types.str "Austin Horstman" "The full name of the user.";
    email = mkOpt types.str "khaneliman12@gmail.com" "The email of the user.";

    home = mkOpt (types.nullOr types.str) home-directory "The user's home directory.";
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
        username = mkDefault cfg.name;
        homeDirectory = mkDefault cfg.home;

        shellAliases = {
          # File management
          rcp = "${getExe pkgs.rsync} -rahP --mkpath --modify-window=1"; # Rsync copy keeping all attributes,timestamps,permissions"
          rmv = "${getExe pkgs.rsync} -rahP --mkpath --modify-window=1 --remove-sent-files"; # Rsync move keeping all attributes,timestamps,permissions
          tarnow = "${getExe pkgs.gnutar} -acf ";
          untar = "${getExe pkgs.gnutar} -zxvf ";
          wget = "${getExe pkgs.wget} -c ";

          # Navigation shortcuts
          home = "cd ~";
          dots = "cd $DOTS_DIR";
          ".." = "cd ..";
          "..." = "cd ../..";
          "...." = "cd ../../..";
          "....." = "cd ../../../..";
          "......" = "cd ../../../../..";

          # Colorize output
          dir = "${pkgs.coreutils}/bin/dir --color=auto";
          egrep = "${pkgs.gnugrep}/bin/egrep --color=auto";
          fgrep = "${pkgs.gnugrep}/bin/fgrep --color=auto";
          grep = "${getExe pkgs.gnugrep} --color=auto";
          vdir = "${pkgs.coreutils}/bin/vdir --color=auto";

          # Misc
          clear = "clear && ${getExe pkgs.fastfetch}";
          clr = "clear";
          pls = "sudo";
          usage = "${pkgs.coreutils}/bin/du -ah -d1 | sort -rn 2>/dev/null";

          # Cryptography
          genpass = "${pkgs.openssl}/bin/openssl rand - base64 20"; # Generate a random, 20-charactered password
          sha = "shasum -a 256"; # Test checksum
          sshperm = ''${pkgs.findutils}/bin/find .ssh/ -type f -exec chmod 600 {} \;; ${pkgs.findutils}/bin/find .ssh/ -type d -exec chmod 700 {} \;; ${pkgs.findutils}/bin/find .ssh/ -type f -name "*.pub" -exec chmod 644 {} \;'';
        };
      };
    }
  ]);
}
