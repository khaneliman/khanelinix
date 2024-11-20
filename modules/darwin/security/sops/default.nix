{
  config,
  lib,
  root,
  ...
}:
let
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt mkOpt;

  cfg = config.khanelinix.security.sops;
in
{
  options.khanelinix.security.sops = with lib.types; {
    enable = mkBoolOpt false "Whether to enable sops.";
    defaultSopsFile = mkOpt path null "Default sops file.";
    sshKeyPaths = mkOpt (listOf path) [ "/etc/ssh/ssh_host_ed25519_key" ] "SSH Key paths to use.";
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
        sopsFile = root + "/secrets/khanelimac/khaneliman/default.yaml";
      };
    };
  };
}
