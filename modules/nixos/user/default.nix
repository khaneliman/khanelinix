{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) types;
  inherit (lib.internal) mkOpt;

  cfg = config.khanelinix.user;

  defaultIcon = pkgs.stdenvNoCC.mkDerivation {
    name = "default-icon";
    src = ./. + "/${defaultIconFileName}";

    dontUnpack = true;

    installPhase = ''
      cp $src $out
    '';

    passthru = { fileName = defaultIconFileName; };
  };
  defaultIconFileName = "profile.png";

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
    email = mkOpt str "khaneliman12@gmail.com" "The email of the user.";
    extraGroups = mkOpt (listOf str) [ ] "Groups for the user to be assigned.";
    extraOptions =
      mkOpt attrs { }
        "Extra options passed to <option>users.users.<name></option>.";
    fullName = mkOpt str "Austin Horstman" "The full name of the user.";
    icon =
      mkOpt (nullOr package) defaultIcon
        "The profile picture to use for the user.";
    initialPassword =
      mkOpt str "password"
        "The initial password to use when the user is first created.";
    name = mkOpt str "khaneliman" "The name to use for the user account.";
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
        inherit (cfg) name initialPassword;

        extraGroups = [ "wheel" ] ++ cfg.extraGroups;
        group = "users";
        home = "/home/${cfg.name}";
        isNormalUser = true;
        shell = pkgs.zsh;
        uid = 1000;
      }
      // cfg.extraOptions;
  };
}
