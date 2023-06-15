{ options
, config
, lib
, pkgs
, inputs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.display-managers.sddm;
in
{
  options.khanelinix.display-managers.sddm = with types; {
    enable = mkBoolOpt false "Whether or not to enable sddm.";
  };

  config = mkIf cfg.enable
    {
      environment.systemPackages = with pkgs; [
        # sddm
        inputs.sddm-catppuccin.packages.${hostPlatform.system}.sddm-catppuccin
      ];

      services.xserver = {
        enable = true;

        libinput.enable = true;
        displayManager = {
          sddm = {
            enable = true;
            theme = "catppuccin";
          };
        };
      };

      system.activationScripts.postInstallHyprland = stringAfter [ "users" ] ''
        echo "Setting sddm permissions for user icon"
        ${pkgs.acl}/bin/setfacl -m u:sddm:x /home/${config.khanelinix.user.name}
        ${pkgs.acl}/bin/setfacl -m u:sddm:r /home/${config.khanelinix.user.name}/.face.icon || true
      '';
    };
}

