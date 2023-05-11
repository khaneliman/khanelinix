{ options
, config
, pkgs
, lib
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.user;
  defaultIconFileName = "profile.png";
  defaultIcon = pkgs.stdenvNoCC.mkDerivation {
    name = "default-icon";
    src = ./. + "/${defaultIconFileName}";

    dontUnpack = true;

    installPhase = ''
      cp $src $out
    '';

    passthru = { fileName = defaultIconFileName; };
  };
  propagatedIcon =
    pkgs.runCommandNoCC "propagated-icon"
      { passthru = { fileName = cfg.icon.fileName; }; }
      ''
        local target="$out/share/khanelinix.icons/user/${cfg.name}"
        mkdir -p "$target"

        cp ${cfg.icon} "$target/${cfg.icon.fileName}"
      '';
in
{
  options.khanelinix.user = with types; {
    name = mkOpt str "khaneliman" "The name to use for the user account.";
    fullName = mkOpt str "Austin Horstman" "The full name of the user.";
    email = mkOpt str "khaneliman.2@gmail.com" "The email of the user.";
    initialPassword =
      mkOpt str "password"
        "The initial password to use when the user is first created.";
    icon =
      mkOpt (nullOr package) defaultIcon
        "The profile picture to use for the user.";
    extraGroups = mkOpt (listOf str) [ ] "Groups for the user to be assigned.";
    extraOptions =
      mkOpt attrs { }
        "Extra options passed to <option>users.users.<name></option>.";
  };

  config = {
    environment.systemPackages = with pkgs; [
      cowsay
      fortune
      lolcat
      khanelinix.cowsay-plus
      propagatedIcon
    ];

    programs.zsh = {
      enable = true;
      autosuggestions.enable = true;
      histFile = "$XDG_CACHE_HOME/zsh.history";
    };

    khanelinix.home = {
      file = {
        "Desktop/.keep".text = "";
        "Documents/.keep".text = "";
        "Downloads/.keep".text = "";
        "Music/.keep".text = "";
        "Pictures/.keep".text = "";
        "Videos/.keep".text = "";
        "work/.keep".text = "";
        ".face".source = cfg.icon;
        ".face.icon".source = cfg.icon;
        "Pictures/${
          cfg.icon.fileName or (builtins.baseNameOf cfg.icon)
        }".source =
          cfg.icon;
      };

      configFile = {
        "sddm/faces/.${cfg.name}".source = cfg.icon;
      };

      extraOptions = {
        home.shellAliases = {
          ls = "lsd -al --color=always --group-directories-first"; # preferred listing                   
          la = "lsd -a --color=always --group-directories-first"; # all files and dirs                  
          ll = "lsd -l --color=always --group-directories-first"; # long format                         
          lt = "lsd -a --tree --color=always --group-directories-first -I .git"; # tree listing          
          lst = "lsd -al --tree --color=always --group-directories-first -I .git"; # tree listing        
          llt = "lsd -l --tree --color=always --group-directories-first -I .git"; # tree listing         
          l = "lsd -a | egrep '^\.'"; # show only dotfilesalias ls='lsd -a' 

          lc = "${pkgs.colorls}/bin/colorls --sd";
          lcg = "lc --gs";
          lcl = "lc -1";
          lclg = "lc -1 --gs";
          lcu = "${pkgs.colorls}/bin/colorls -U";
          lclu = "${pkgs.colorls}/bin/colorls -U -1";

          # File management
          rcp = "rsync -rahP --mkpath --modify-window=1"; # Rsync copy keeping all attributes,timestamps,permissions"
          rmv = "rsync -rahP --mkpath --modify-window=1 --remove-sent-files"; # Rsync move keeping all attributes,timestamps,permissions
          tarnow = "tar -acf ";
          untar = "tar -zxvf ";
          wget = "wget -c ";

          # Navigation shortcuts
          home = "cd ~";
          dots = "cd $DOTS_DIR";
          ".." = "cd ..";
          "..." = "cd ../..";
          "...." = "cd ../../..";
          "....." = "cd ../../../..";
          "......" = "cd ../../../../..";

          # Colorize output
          dir = "dir --color=auto";
          vdir = "vdir --color=auto";
          grep = "grep --color=auto";
          fgrep = "fgrep --color=auto";
          egrep = "egrep --color=auto";

          # Misc
          pls = "sudo";
          clr = "clear";
          clear = "clear && fastfetch";
          usage = "du -ah -d1 | sort -rn 2>/dev/null";

          # Cryptography
          genpass = "openssl rand - base64 20"; # Generate a random, 20-charactered password
          sha = "shasum -a 256"; # Test checksum
          sshperm = ''find .ssh/ -type f -exec chmod 600 {} \;; find .ssh/ -type d -exec chmod 700 {} \;; find .ssh/ -type f -name "*.pub" -exec chmod 644 {} \;'';
        };

        programs = {
          zsh = {
            enable = true;
            enableCompletion = true;
            enableAutosuggestions = true;
            enableSyntaxHighlighting = true;

            initExtra = ''
              # Fix an issue with tmux.
              export KEYTIMEOUT=1

              # Use vim bindings.
              set -o vi

              ${pkgs.toilet}/bin/toilet -f future "Plus Ultra" --gay

              # Improved vim bindings.
              source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
            '';

            shellAliases = {
              say = "${pkgs.toilet}/bin/toilet -f pagga";
            };

            plugins = [
              {
                name = "zsh-nix-shell";
                file = "nix-shell.plugin.zsh";
                src = pkgs.fetchFromGitHub {
                  owner = "chisui";
                  repo = "zsh-nix-shell";
                  rev = "v0.4.0";
                  sha256 = "037wz9fqmx0ngcwl9az55fgkipb745rymznxnssr3rx9irb6apzg";
                };
              }
            ];
          };
        };
      };
    };

    users.users.${cfg.name} =
      {
        isNormalUser = true;

        inherit (cfg) name initialPassword;

        home = "/home/${cfg.name}";
        group = "users";

        shell = pkgs.fish;

        # Arbitrary user ID to use for the user. Since I only
        # have a single user on my machines this won't ever collide.
        # However, if you add multiple users you'll need to change this
        # so each user has their own unique uid (or leave it out for the
        # system to select).
        uid = 1000;

        extraGroups = [ "wheel" ] ++ cfg.extraGroups;
      }
      // cfg.extraOptions;
  };
}
