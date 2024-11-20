{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf getExe' stringAfter;
  inherit (lib.khanelinix) mkBoolOpt enabled;

  cfg = config.khanelinix.display-managers.sddm;
in
{
  options.khanelinix.display-managers.sddm = {
    enable = mkBoolOpt false "Whether or not to enable sddm.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      catppuccin-sddm-corners
      sddm
    ];

    services = {
      displayManager = {
        sddm = {
          inherit (cfg) enable;
          theme = "catppuccin-sddm-corners";
          wayland = enabled;
        };
      };
    };

    system.activationScripts.postInstallSddm =
      stringAfter [ "users" ] # bash
        ''
          echo "Setting sddm permissions for user icon"
          ${getExe' pkgs.acl "setfacl"} -m u:sddm:x /home/${config.khanelinix.user.name}
          ${getExe' pkgs.acl "setfacl"} -m u:sddm:r /home/${config.khanelinix.user.name}/.face.icon || true
        '';
  };
}
