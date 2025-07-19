{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.shell.bash;
in
{
  options.khanelinix.programs.terminal.shell.bash = {
    enable = lib.mkEnableOption "bash";
  };

  config = mkIf cfg.enable {
    programs.bash = {
      enable = true;
      enableCompletion = true;

      initExtra = lib.optionalString config.programs.fastfetch.enable ''
        fastfetch
      '';
    };
  };
}
