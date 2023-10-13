{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.cli-apps.k9s;

  fromYAML = f:
    let
      jsonFile =
        pkgs.runCommand "in.json"
          {
            nativeBuildInputs = [ pkgs.jc ];
          } ''
          jc --yaml < "${f}" > "$out"
        '';
    in
    builtins.elemAt (builtins.fromJSON (builtins.readFile jsonFile)) 0;
in
{
  options.khanelinix.cli-apps.k9s = {
    enable = mkBoolOpt false "Whether or not to enable k9s.";
  };

  config = mkIf cfg.enable {
    programs.k9s = {
      enable = true;
      package = pkgs.k9s;

      skin = fromYAML (pkgs.catppuccin + "/k9s/themes/macchiato.yml");
    };
  };
}
