{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.terminal.tools.act;
in
{
  options.${namespace}.programs.terminal.tools.act = {
    enable = mkBoolOpt false "Whether or not to enable act.";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.act ];

    home.file.".actrc".text =
      lib.mkIf (pkgs.stdenv.hostPlatform.isDarwin && pkgs.stdenv.hostPlatform.isAarch64)
        ''
          --container-architecture linux/amd64
        '';
  };
}
