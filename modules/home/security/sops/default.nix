{ options
, config
, lib
, inputs
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.internal) mkBoolOpt mkOpt;
  inherit (inputs) sops-nix;

  cfg = config.khanelinix.security.sops;
in
{
  imports = [
    sops-nix.homeManagerModules.sops
  ];

  options.khanelinix.security.sops = with types; {
    enable = mkBoolOpt false "Whether to enable sops.";
    sshKeyPaths = mkOpt (listOf path) [ ] "SSH Key paths to use.";
    defaultSopsFile = mkOpt path null "Default sops file.";
  };

  config = mkIf cfg.enable {
    sops = {
      inherit (cfg) defaultSopsFile;

      age = {
        generateKey = true;
        keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
        sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ] ++ cfg.sshKeyPaths;
      };
    };
  };
}
