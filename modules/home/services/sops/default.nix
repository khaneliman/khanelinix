{
  config,
  lib,
  pkgs,
  root,
  ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.khanelinix) mkBoolOpt mkOpt;

  cfg = config.khanelinix.services.sops;
in
{
  options.khanelinix.services.sops = with types; {
    enable = mkBoolOpt false "Whether to enable sops.";
    defaultSopsFile = mkOpt path null "Default sops file.";
    sshKeyPaths = mkOpt (listOf path) [ ] "SSH Key paths to use.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      age
      sops
      ssh-to-age
    ];

    sops = {
      inherit (cfg) defaultSopsFile;
      defaultSopsFormat = "yaml";

      age = {
        generateKey = true;
        keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
        sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ] ++ cfg.sshKeyPaths;
      };

      secrets = {
        nix = {
          sopsFile = root + "/secrets/khaneliman/default.yaml";
          path = "${config.home.homeDirectory}/.config/nix/nix.conf";
        };
      };
    };
  };
}
