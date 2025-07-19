{
  config,
  lib,

  ...
}:
let
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.security.sops;
in
{
  options.khanelinix.security.sops = {
    enable = lib.mkEnableOption "sops";
    defaultSopsFile = mkOpt lib.types.path null "Default sops file.";
    sshKeyPaths = mkOpt (with lib.types; listOf path) [
      "/etc/ssh/ssh_host_ed25519_key"
    ] "SSH Key paths to use.";
  };

  config = lib.mkIf cfg.enable {
    sops = {
      inherit (cfg) defaultSopsFile;

      age = {
        inherit (cfg) sshKeyPaths;

        keyFile = "${config.users.users.${config.khanelinix.user.name}.home}/.config/sops/age/keys.txt";
      };
    };

    sops.secrets = {
      "khanelimac_khaneliman_ssh_key" = {
        sopsFile = lib.getFile "secrets/khanelimac/khaneliman/default.yaml";
      };
    };
  };
}
