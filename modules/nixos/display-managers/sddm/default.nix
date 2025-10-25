{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf getExe' stringAfter;
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.display-managers.sddm;

  userName = config.khanelinix.user.name;
in
{
  options.khanelinix.display-managers.sddm = {
    enable = lib.mkEnableOption "sddm";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      catppuccin-sddm-corners
    ];

    khanelinix.home.configFile =
      let
        inherit (config.home-manager.users.${userName}.khanelinix.user) icon;
      in
      lib.mkIf (icon != null) {
        "sddm/faces/.${userName}".source = icon;
      };

    services = {
      displayManager = {
        sddm = {
          inherit (cfg) enable;
          # package = pkgs.libsForQt5.sddm;
          # TODO: update theme support
          package = pkgs.kdePackages.sddm;
          theme = "catppuccin-sddm-corners";
          wayland = enabled;
        };
      };
    };

    system.activationScripts.postInstallSddm = stringAfter [ "users" ] /* Bash */ ''
      echo "Setting sddm permissions for user icon"
      ${getExe' pkgs.acl "setfacl"} -m u:sddm:x /home/${userName}
      ${getExe' pkgs.acl "setfacl"} -m u:sddm:r /home/${userName}/.face.icon || true
    '';
  };
}
