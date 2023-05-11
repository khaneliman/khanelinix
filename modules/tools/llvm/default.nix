{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.tools.llvm;
in {
  options.khanelinix.tools.llvm = with types; {
    enable = mkBoolOpt false "Whether or not to enable llvm.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      llvm
    ];
  };
}
