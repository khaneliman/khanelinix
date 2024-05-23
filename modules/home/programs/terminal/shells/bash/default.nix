{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.terminal.shell.bash;
in
{
  options.${namespace}.programs.terminal.shell.bash = {
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
