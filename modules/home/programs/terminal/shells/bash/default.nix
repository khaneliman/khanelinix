{
  config,
  lib,
  khanelinix-lib,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (khanelinix-lib) mkBoolOpt;

  cfg = config.khanelinix.programs.terminal.shell.bash;
in
{
  options.khanelinix.programs.terminal.shell.bash = {
    enable = mkBoolOpt false "Whether to enable bash.";
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
