{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.security.sops;
in
{
  options.${namespace}.security.sops = {
    enable = mkBoolOpt false "Whether to enable sops.";
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

        keyFile = "${config.users.users.${config.${namespace}.user.name}.home}/.config/sops/age/keys.txt";
      };
    };

    sops.secrets = {
      "khanelinix_khaneliman_ssh_key" = {
        sopsFile = lib.snowfall.fs.get-file "secrets/khanelinix/khaneliman/default.yaml";
      };
    };
  };
}
