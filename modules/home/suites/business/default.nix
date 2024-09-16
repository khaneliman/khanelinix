{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt enabled;

  cfg = config.${namespace}.suites.business;
in
{
  options.${namespace}.suites.business = {
    enable = mkBoolOpt false "Whether or not to enable business configuration.";
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        calcurse
        # FIXME: package broken because of dependency textual being broken because of a dependency
        # on tree-sitter-languages being broken because of a dependency on tree-sitter0_21 which is
        # marked as incompatible with python3.12
        dooit
        jrnl
        np
        teams-for-linux
      ]
      ++ lib.optionals stdenv.isLinux [ libreoffice ];

    khanelinix = {
      programs = {
        graphical = {
          apps = {
            _1password = enabled;
          };
        };
      };
    };
  };
}
