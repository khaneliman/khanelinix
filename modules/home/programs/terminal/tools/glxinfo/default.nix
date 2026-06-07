{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.glxinfo;

  mesaDemosWithoutEngine = pkgs.symlinkJoin {
    name = "mesa-demos-without-engine-${pkgs.mesa-demos.version}";
    paths = [ pkgs.mesa-demos ];
    # mesa-demos ships generic `engine`, which collides with ollama in home profiles.
    postBuild = ''
      rm -f "$out/bin/engine"
    '';
  };
in
{
  options.khanelinix.programs.terminal.tools.glxinfo = {
    enable = lib.mkEnableOption "glxinfo";
  };

  config = mkIf cfg.enable { home.packages = [ mesaDemosWithoutEngine ]; };
}
