{ options
, config
, lib
, pkgs
, inputs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.tools.bat;
in
{
  options.khanelinix.tools.bat = with types; {
    enable = mkBoolOpt false "Whether or not to enable bat.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      bat
    ];

    khanelinix.home = {
      configFile = with inputs; {
        "bat/".source = dotfiles.outPath + "/dots/shared/home/.config/bat";
      };
      extraOptions = {
        home.shellAliases = {
          cat = "bat";

        };
      };
    };

    system.activationScripts.postInstallBat = stringAfter [ "users" ] ''
      echo "Running command after bat installation"
      # Your command here, for example:
      ${pkgs.bat}/bin/bat cache --build
    '';
  };
}
