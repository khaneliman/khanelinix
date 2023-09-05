{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.tools.git-crypt;
in
{
  options.khanelinix.tools.git-crypt = with types; {
    enable = mkBoolOpt false "Whether or not to enable git-crypt.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      git-crypt
    ];
  };
}
