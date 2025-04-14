{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf getExe' stringAfter;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.display-managers.sddm;

  userName = config.${namespace}.user.name;
in
{
  options.${namespace}.display-managers.sddm = {
    enable = lib.mkEnableOption "sddm";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      catppuccin-sddm-corners
    ];

    ${namespace}.home.configFile =
      let
        icon = config.home-manager.users.${userName}.${namespace}.user.icon;
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

    system.activationScripts.postInstallSddm =
      stringAfter [ "users" ] # Bash
        ''
          echo "Setting sddm permissions for user icon"
          ${getExe' pkgs.acl "setfacl"} -m u:sddm:x /home/${userName}
          ${getExe' pkgs.acl "setfacl"} -m u:sddm:r /home/${userName}/.face.icon || true
        '';
  };
}
