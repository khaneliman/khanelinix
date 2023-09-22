{ options
, config
, lib
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.internal) mkBoolOpt mkOpt;
  cfg = config.khanelinix.security.sops;
in
{
  options.khanelinix.security.sops = with types; {
    enable = mkBoolOpt false "Whether to enable sops.";
    sshKeyPaths = mkOpt (listOf path) [ ] "SSH Key paths to use.";
    defaultSopsFile = mkOpt path null "Default sops file.";
  };

  config = mkIf cfg.enable { };
}
