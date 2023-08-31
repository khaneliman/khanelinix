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
      { passthru = { inherit (cfg.icon) fileName; }; }
      ''
        local target="$out/share/icons/user/${cfg.name}"
        mkdir -p "$target"

        cp ${cfg.icon} "$target/${cfg.icon.fileName}"
      '';
in
{
  options.khanelinix.user = with types; {
    name = mkOpt str "khaneliman" "The name to use for the user account.";
    fullName = mkOpt str "Austin Horstman" "The full name of the user.";
    email = mkOpt str "khaneliman12@gmail.com" "The email of the user.";
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
      fortune
      lolcat
      propagatedIcon
    ];

    programs.zsh = {
      enable = true;
      autosuggestions.enable = true;
      histFile = "$XDG_CACHE_HOME/zsh.history";
    };

    khanelinix.home = {
      file = {
        ".face".source = cfg.icon;
        ".face.icon".source = cfg.icon;
        "Desktop/.keep".text = "";
        "Documents/.keep".text = "";
        "Downloads/.keep".text = "";
        "Music/.keep".text = "";
        "Pictures/.keep".text = "";
        "Videos/.keep".text = "";
        "Pictures/${
          cfg.icon.fileName or (builtins.baseNameOf cfg.icon)
        }".source =
          cfg.icon;
      };

      configFile = {
        "sddm/faces/.${cfg.name}".source = cfg.icon;
      };

      extraOptions.home.shellAliases = {
        nixre = "sudo flake switch";
      };
    };

    users.users.${cfg.name} =
      {
        isNormalUser = true;

        inherit (cfg) name initialPassword;

        home = "/home/${cfg.name}";
        group = "users";

        shell = pkgs.zsh;

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
