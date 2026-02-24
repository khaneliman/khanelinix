{
  config,
  lib,

  pkgs,
  ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.services.sops;
in
{
  options.khanelinix.services.sops = with types; {
    enable = lib.mkEnableOption "sops";
    defaultSopsFile = mkOpt path null "Default sops file.";
    sshKeyPaths = mkOpt (listOf path) [ ] "SSH Key paths to use.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      age
      sops
      # NOTE: Adding a new machine key
      # 1. Convert SSH key: ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt
      # 2. Add the public key to `.sops.yaml` under both the machine-specific and `secrets/khaneliman/` rules
      # 3. Run `sops updatekeys` on all affected secret files from a machine that can already decrypt them
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
          sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
          path = "${config.home.homeDirectory}/.config/nix/nix.conf";
        };
      };
    };
  };
}
